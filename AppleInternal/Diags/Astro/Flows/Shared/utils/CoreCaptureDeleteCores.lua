local Step = require 'flow.Step'
local epcall = require 'exceptions.epcall'
local fs = require 'filesystem'
local corecapture = require 'corecapture'

return function()
    return Step ('Delete CoreCapture folder', function()
                epcall(function () fs.remove(corecapture.CORE_CAPTURE_FOLDER) end)
            end)
end
