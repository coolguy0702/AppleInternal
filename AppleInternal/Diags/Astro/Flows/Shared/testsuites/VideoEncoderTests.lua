local flowconfig = require 'flowconfig'
local Sequence  = require 'flow.Sequence'
local AVE = require 'tests.AVE'

return function()
    return Sequence {
        name = "Video Encoder Tests",
        description = "Video Encoder Tests",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        AVE()
    }
end
