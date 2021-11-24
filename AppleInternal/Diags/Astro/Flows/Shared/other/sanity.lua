-- This is a short sequence which can run 1 of each fast test, to get a general idea if the sequence looks ok.
local FactoryStation = require 'manufacturing.FactoryStation'

local CameraUnitInfo = require 'info.CameraUnitInfo'
local VideoDecoderTests = require 'testsuites.VideoDecoderTests'
local VideoEncoderTests = require 'testsuites.VideoEncoderTests'
local BasebandOnlineMode = require 'utils.BasebandOnlineMode'
local ComponentTests = require 'testsuites.ComponentTests'
local CopyAstroDebug = require 'utils.CopyAstroDebug'

return FactoryStation {
    station = "OFFLINE-BURNIN",
    continue_on_fail = true,

    CameraUnitInfo(),
    BasebandOnlineMode(),

    ComponentTests(),
    VideoEncoderTests(),
    VideoDecoderTests(),
    on_exit = {
        CopyAstroDebug(),
    }
}
