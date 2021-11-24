local objects = require "objects"
local Class = objects.Class
local DebugShell = require 'flowextensions.DebugShell'
local process = require 'process'
local processutils = require 'processutils'
local verify = require 'verify'
local time = require 'time'

local function ave_idle(enable)
    local value = 0
    local initial_value = 6
    local end_value = 3
    local increment = -1

    print('Setting AVE Idle: ' .. tostring(enable))
    if enable == true then
        -- If disabling, need to run commands in reverse order
        value = 1
        initial_value = 3
        end_value = 6
        increment = 1
    end

    for i=initial_value,end_value,increment do
        local command = '/usr/local/bin/pmgrtest k "enableDeviceClock(' .. value .. ',,' .. i .. ',ave)"'
        for retry_count=5,1,-1 do -- 5 retries
            local success = processutils.shell(command, 30)

            if success.code ~= 0 then
                print('Retrying enable AVE with command ' .. command)
                if retry_count == 1 then
                    error('Multiple failures setting AVE')
                end
            else
                break
            end
        end
    end

end

-- Transfer values are priority times 100 , eg. 100 means P1
local function gpu_perf_state(state)
    verify.number(state, 'Expected state to be a number')
    print('Setting GPU Perf State ' .. state)

    local command = '/usr/local/bin/agx_util -setControllerOverride perf transfer ' .. state * 100
    local success = processutils.shell(command, 30)

    if success.code ~= 0 then
        error('Unable to set perf state with command ' .. command)
    end

end


-- Need to prevent GPU from idling
local function gpu_idle_poweroff(enabled)
    local command = '/usr/local/bin/agx_util -gpu-idle-off 1'

    print('Setting GPU Idle Poweroff: ' .. tostring(enabled))

    if enabled == false then
        command = '/usr/local/bin/agx_util -gpu-idle-off 0'
    end

    local success = processutils.shell(command, 30)

    if success.code ~= 0 then
        error('Unable to change GPU idle: ' .. command)
    end

end


local function ane_idle_process()
    print('Setting ANE to idle')

    local success = processutils.shell('/bin/echo "powermgmt off \n on" > /tmp/ane_idle.txt', 30)
    if success.code ~= 0 then
        error('Unable to change write ANE script')
    end

    local ane_process = process.Process {
        path = '/usr/local/bin/anetest',
        arguments = {'-s', '/tmp/ane_idle.txt'}
    }

    if not ane_process then
        error('Unable to create ANE idle process')
    end

    ane_process:launch()

    return ane_process
end

local function fbdraw_black_process()
    print('Drawing black to screen')

    local success = processutils.shell('/usr/bin/mkfifo /tmp/fbdraw_pipe', 30)
    if success.code ~= 0 then
        print('Unable to create pipe. It may already exist, which is fine')
    end

    local fbdraw_process = process.Process {
        path = '/bin/sh',
        arguments = {'-c', '/usr/bin/tail -f /tmp/fbdraw_pipe | /usr/local/bin/fbdraw -i'}
    }

    if not fbdraw_process then
        error('Unable to load fbdraw')
    end

    fbdraw_process:launch()

    success = processutils.shell('/bin/echo "display:set_background_color{0,0,0}" > /tmp/fbdraw_pipe', 30)
    if success.code ~= 0 then
        error('Unable to write to pipe')
    end

    return fbdraw_process
end

local function qos_minimum(enabled)
    local command = '/usr/local/bin/clpcctrl -f min'

    print('Setting QOS : ' .. command)

    if enabled == false then
        command = '/usr/local/bin/clpcctrl -d'
    end

    local success = processutils.shell(command, 30)

    if success.code ~= 0 then
        error('Unable to set qos: ' .. command)
    end

end

local MtrShell = Class(DebugShell)

function MtrShell:init(perf_state)
    verify.number(perf_state, 'Expected state to be a number')

    local label = 'P' .. perf_state
    local pdca_path = '/private/var/logs/BurnIn/PDCA/_pdca_osdmetrology_' .. label .. '.plist'
    DebugShell.init(self, {
        name = 'MTR',
        description = 'MTR ' .. label,
        command = '/usr/local/bin/OSDMetrologyTester temperature --errorLimits=YES --label=' .. label .. ' --pdcaPath=' .. pdca_path,
        pdca_plist_paths = {pdca_path},
        timeout = 30,
    })

    self.perf_state = perf_state
end

function MtrShell:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    qos_minimum(true)
--    self.fbdraw_black_process = fbdraw_black_process()
    gpu_idle_poweroff(false)
    ave_idle(true)
    self.ane_idle_process = ane_idle_process()
    gpu_perf_state(self.perf_state)
    print('Sleeping 5s for perf state')
    time.sleep(5) -- Need time for perf state to be applied
end

function MtrShell:teardown()
    DebugShell.teardown(self) -- Have DebugShell do teardown first

--    if self.fbdraw_black_process.is_running then
--        local pid = self.fbdraw_black_process.pid
--        -- Kill the children since we're piping
--        print('Killing fbdraw pid ' .. pid)
--        processutils.shell('/bin/kill -- -' .. pid)
--    else
--        error('fbdraw process was not running')
--    end

    if self.ane_idle_process.is_running then -- Allow ANE idle
        print('Killing ANE idle')
        self.ane_idle_process:kill()
    else
        error('ANE process was not running')
    end

    ave_idle(false)

    gpu_idle_poweroff(true)
    qos_minimum(false)
end

function MtrShell:debug_result(result)
    processutils.shell('/usr/local/bin/pmgrtest mtr')
    DebugShell.debug_result(self, result)
end

return MtrShell
