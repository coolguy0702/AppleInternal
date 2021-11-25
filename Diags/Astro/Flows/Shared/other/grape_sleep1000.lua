local FactoryStation = require 'manufacturing.FactoryStation'
local Loop = require 'flow.Loop'
local Step = require 'flow.Step'
local GrapeResets = require 'tests.GrapeResets'
local ComponentGrapeCriticalError = require 'tests.ComponentGrapeCriticalError'
local Reboot = require 'flow.Reboot'
local Sleep = require 'flow.Sleep'
local Shell = require 'flow.Shell'
local processutils = require 'processutils'

local function GrapeSleepLoop(cycle_count, desc)
    cycle_count = cycle_count or 1
    -- add ": Desc" if provided
    desc = desc and " " .. desc or ""

    return Loop(cycle_count) {
        name = 'SleepLoop x' .. cycle_count .. desc,
        results_name = 'SleepLoop' .. desc,
        description = cycle_count .. "x sleep cycle(s)" .. desc,
        continue_on_fail = true,

        Sleep(10), -- Sleep for 10s
        Shell {
            name = 'Start mtlogging after sleep',
            command = '/usr/local/bin/mtlog -humantime >> $ASTRO_WORKING_DIRECTORY/mtlog.txt &'
        },
        GrapeResets(),
        ComponentGrapeCriticalError(),
        Step {
            name = 'Kill mtlog',
            description = 'Kill mtlog',
            main = function ()
                processutils.shell('/usr/bin/killall -2 mtlog')
            end
        },
    }
end

return FactoryStation {
    station = "OFFLINE-BURNIN",

    on_enter = {
        Shell {
            name = 'Start mtlogging at boot',
            command = '/usr/local/bin/mtlog -humantime >> $ASTRO_WORKING_DIRECTORY/mtlog.txt &'
        },
    },

    Shell {
        name = 'Enable mtlog cache',
        command = '/usr/local/bin/diagstool bootargs --add aid-cache-logs=1'
    },
    Shell {
        name = 'Set mtlog cache size bootarg',
        command = '/usr/local/bin/diagstool bootargs --add aid-cache-logs-size=5000000'
    },
    Reboot(),

    GrapeSleepLoop(1000),

    on_exit = {
        Shell {
            name = 'Disable mtlog cache',
            command = '/usr/local/bin/diagstool bootargs --remove aid-cache-logs'
        },
        Shell {
            name = 'Remove mtlog cache size bootarg',
            command = '/usr/local/bin/diagstool bootargs --remove aid-cache-logs-size'
        },
    }
}
