local verify = require 'verify'
local objects = require 'objects'
local processutils = require 'processutils'
local PowerTestShell = require 'classes.PowerTestShell'
local fs = require 'filesystem'
local epcall = require 'exceptions.epcall'

local ComponentInductiveCharger = objects.Class(PowerTestShell)

local function run_command(node, debug_dir, command, file_name, description)
    local file_path = fs.path.join(debug_dir, file_name)

    local success, _ = epcall(function ()
        processutils.shell(command .. ' > "' .. file_path .. '"', 30)
    end)

    if success then
        node:save_file_result {
            path = file_path,
            metadata = {
                description = description
            }
        }
    end
end

function ComponentInductiveCharger:init(args)
    verify.string(args.inductive_charger_name, "inductive_charger_name should be a string")

    PowerTestShell.init(self, {
        name = 'Component ' .. args.inductive_charger_name,
        command = 'fwVersion=`/usr/local/bin/c26tool status | grep VERSION` && echo $fwVersion && echo $fwVersion | grep 0x1',
        timeout = 30,
    })
end

function ComponentInductiveCharger:setup()
    PowerTestShell.setup(self) -- Have DebugShell do setup first
    processutils.shell('/usr/local/bin/smcif -w WAFC 25', 30)
end

function ComponentInductiveCharger:teardown()
    PowerTestShell.teardown(self)
    processutils.shell('/usr/local/bin/smcif -w WAFC 0xb 0 0 0', 30)
end

function ComponentInductiveCharger:debug_actions()
    fs.mkdirs(self:debug_log_dir())
    run_command(self, self:debug_log_dir(), '/usr/local/bin/c26tool status', 'c26tool_status.txt', 'c26tool status')
    run_command(self, self:debug_log_dir(), '/usr/local/bin/c26tool logs dump', 'c26tool_logs_dump.txt', 'c26tool logs dump')
    run_command(self, self:debug_log_dir(), '/usr/local/bin/c26tool adc dump', 'c26tool_adc_dump.txt', 'c26tool adc dump')

    PowerTestShell.debug_actions(self)
end

return ComponentInductiveCharger
