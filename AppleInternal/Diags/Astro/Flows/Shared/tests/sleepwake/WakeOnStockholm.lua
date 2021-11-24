local Sequence = require 'flow.Sequence'
local DebugShell = require 'flowextensions.DebugShell'
local ComponentStockholm = require 'tests.ComponentStockholm'

return function()
    return Sequence {
        on_enter = {
            DebugShell {
                name = 'Unload Stockholm services',
                command = '/var/logs/BurnIn/Scripts/stockholm_fw.sh -t unload_services'
            },
            DebugShell {
                name = 'Load Stockholm manufacturing fw',
                command = '/var/logs/BurnIn/Scripts/stockholm_fw.sh -t mfg'
            },
            DebugShell {
                name = 'Load Stockholm services',
                command = '/var/logs/BurnIn/Scripts/stockholm_fw.sh -t load_services'
            },
            ComponentStockholm()
        },

        DebugShell {
            name = 'Wake On Stockholm',
            command = '/usr/local/bin/OSDWakeOn -t stockholm -r 5 -R 5 -b 75',
            timeout = 100
        },
        ComponentStockholm(), -- running another Component check due to silicon bug from N71 rdar 21843653

        on_exit = {
            DebugShell {
                name = 'Unload Stockholm services',
                command = '/var/logs/BurnIn/Scripts/stockholm_fw.sh -t unload_services'
            },
            DebugShell {
                name = 'Load Stockholm production fw',
                command = '/var/logs/BurnIn/Scripts/stockholm_fw.sh -t prod'
            },
            DebugShell {
                name = 'Load Stockholm services',
                command = '/var/logs/BurnIn/Scripts/stockholm_fw.sh -t load_services'
            },
        },
    }
end
