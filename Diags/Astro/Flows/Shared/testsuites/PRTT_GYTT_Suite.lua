local flowconfig = require 'flowconfig'
local Sequence = require 'flow.Sequence'

local GYTTSuite = require 'testsuites.GYTTSuite'
local PRTTBackground = require 'classes.PRTTBackground'

return function()

    return Sequence {
        name = 'PRTT GYTT Suite',
        description = 'PRTT GYTT Suite',
        results_name = 'PRTTGYTTSuite',
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        PRTTBackground {
            duration = 600, -- calculated from adding up the heating from CPU virus
            child = GYTTSuite(),
            prttTag = 'GYTTHeating'
        },
    }
end
