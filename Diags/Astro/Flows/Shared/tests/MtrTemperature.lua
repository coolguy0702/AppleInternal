local classes = require 'classes'
local WithDisplayOn = require 'flowextensions.WithDisplayOn'
local Sequence = require 'flow.Sequence'
local DebugShell = require 'flowextensions.DebugShell'

return function()
    local mtr_seq = {
        name = "MtrTemperature",
        description = "MTR Temperature Test Sequence",

        on_enter = DebugShell {
            name = 'Display power off',
            description = 'Display power off',
            command = '/usr/local/bin/powerswitch lcd off'
        },

        on_exit = DebugShell {
            name = 'Display power on',
            description = 'Display power on',
            command = '/usr/local/bin/powerswitch lcd on'
        }
    }

    -- P1 only for now
    for i=1,1 do -- i=1,6 means P1 to P6
        table.insert(mtr_seq, classes.MtrShell(i))
    end

    return WithDisplayOn(Sequence(mtr_seq))
end
