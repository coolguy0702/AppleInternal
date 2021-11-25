-- <rdar://problem/48899749>
-- https://confluence.sd.apple.com/pages/viewpage.action?pageId=260035850
local astro = require 'astro'
local objects = require 'objects'
local Node = require 'flow.classes.Node'
local process = require 'process'
local time = require 'time'
local processutils = require 'processutils'
local verify = require 'verify'

local BURNIN_DIR_PATH = '/private/var/logs/BurnIn'

local PRTTHeating = objects.Class(Node)

function PRTTHeating:init(args)
    verify.table(args, 'args should be a table')
    verify.string(args.prttTag, 'args.prttTag should be a string')
    verify.number(args.duration, 'args.duration should be a number')

    self.prttTag = args.prttTag
    self.duration = args.duration

    local representation = astro.viz.Step {
        metadata = {
            name = 'PRTT Heating - ' .. self.prttTag .. ' - ' .. self.duration,
            results_name = 'PRTT_Heating_' .. self.prttTag,
            description = 'PRTT Heating - ' .. self.prttTag,
            [ astro.viz.MetadataKeys.CAUSES_REBOOT ] = false,
        }
    }
    Node.init(self, representation)
end

function PRTTHeating:run()
    processutils.shell('/usr/local/bin/setbright 1')
    processutils.shell('/usr/local/bin/clpcctrl -f max')

    -- Background buildPRTT
    -- '/usr/local/bin/motiontool buildPRTT ${prttTag}_Heating 0.04 /private/var/logs/BurnIn/prtt.db Run-${prttTag}_Heating &> /dev/null &'
    local build_prtt_cmd = string.format('/usr/local/bin/motiontool buildPRTT %s 0.04 %s/prtt.db Run-%s &> /dev/null &', self.prttTag, BURNIN_DIR_PATH, self.prttTag)
    processutils.shell(build_prtt_cmd)

    -- Background TCO Rising Edge 330 seconds
    -- /usr/local/bin/pressureTester --duration 330 --interval 0.04 --printTemperature >/private/var/logs/BurnIn/pressureTester_heating_${prttTag}_Heating_`date +"%Y-%m-%d_%H-%M-%S"`.log
    local t = os.date('*t') -- time now
    local time_label = table.concat({t.year, t.month, t.day, t.hour, t.min, t.sec}, "-")
    local tco_cmd = string.format('/usr/local/bin/pressureTester --duration 330 --interval 0.04 --printTemperature >%s/pressureTester_heating_%s_%s.log &', BURNIN_DIR_PATH, self.prttTag, time_label)
    processutils.shell(tco_cmd) -- TCO Rising Edge 330 seconds

    -- Background agx_power_test
    processutils.shell('/usr/local/bin/agx_power_test execute --module gpu.balance --submodule balance --thread-count 4194304  --renders-per-cmd-buffer 4 --queues 4 --duration 300 &')

    -- PRTT Thermal Ramp 5 Minute
    -- /usr/local/bin/thermalScreenOneDutyCycle -s -i 0 -l 4096 -f -c 0 -r 5'
    local path = '/usr/local/bin/thermalScreenOneDutyCycle'
    local args = {'-s', '-i', '0', '-l', '4096', '-f', '-c', '0', '-r', '5'}
    local thermalVirusProcess = process.Process {
        path = path,
        arguments = args
    }

    print('Running ' .. path .. ' ' .. table.concat(args, ' '))
    print('Killing after ' .. self.duration .. ' seconds')
    thermalVirusProcess:launch()
    time.sleep(self.duration)
    thermalVirusProcess:kill()

    print('Wait 30 more seconds to finish TCO Rising Edge')
    time.sleep(30)

    processutils.shell('/usr/bin/killall motiontool') -- Killall buildPRTT Heating
    processutils.shell('/usr/local/bin/setbright 0.5') -- set default
    processutils.shell('/usr/local/bin/clpcctrl -d') -- Re-enable dynamic frequency control

end

return PRTTHeating
