local Sequence = require 'flow.Sequence'
local DebugShell = require 'flowextensions.DebugShell'
local ComponentSPU = require 'tests.ComponentSPU'

return function()
    return Sequence {
        on_enter = {
            ComponentSPU()
        },

        DebugShell {
            name = 'Wake On SPU',
            command = '/usr/local/bin/OSDWakeOn -t spu  -r 5 -R 5 -b 30 -a true',
            timeout = 100
        },
    }
end
