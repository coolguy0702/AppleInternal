local flowconfig = require 'flowconfig'
local Sequence = require 'flow.Sequence'
local H264 = require 'tests.AVD_H264'
local HEVC = require 'tests.AVD_HEVC'


return function()

    return Sequence {
        name = "Video Decoder Tests",
        description = "Video Decoder Tests",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        H264(),
        HEVC()
    }
end
