-- Must be run at room temperature; check the generated GYTT makes sense
local Sequence = require 'flow.Sequence'
local Shell = require 'flow.Shell'
local DebugShell = require 'flowextensions.DebugShell'

return function(config)
    -- Default config values
    local offsetThreshold = 1.2
    local slopeLimitOpts = ""

    if config ~= nil then

        if config.offsetThreshold ~= nil then
            offsetThreshold = config.offsetThreshold
        end

        if config.slopeLimitX ~= nil then
            slopeLimitOpts = " -slopeLimitX " .. config.slopeLimitX
        end

        if config.slopeLimitY ~= nil then
            slopeLimitOpts = slopeLimitOpts .. " -slopeLimitY " .. config.slopeLimitY
        end

        if config.slopeLimitZ ~= nil then
            slopeLimitOpts = slopeLimitOpts .. " -slopeLimitZ " .. config.slopeLimitZ
        end
    end

    local gyrosanity_path = '$ASTRO_WORKING_DIRECTORY/logs/GyroSanity/'
    local pdca_path = gyrosanity_path .. 'gyrosanity.plist'
    local cmd = '/usr/local/bin/GyroSanity -offsetThreshold ' .. offsetThreshold ..
                                               ' -pdcaOutputPath ' .. pdca_path ..
                                               ' -rawGyroSampleOutputPath ' .. gyrosanity_path .. 'gyroSanityRawGyroReadings' ..
                                               ' -gyroSampleOutputPath ' ..  gyrosanity_path .. 'gyroSanityGyroReadings' ..
                                               ' -liveGyroSampleOutputPath ' .. gyrosanity_path .. 'gyroSanityLiveGyroReadings' ..
                                               slopeLimitOpts

    return Sequence {
        Shell {
            name = 'Create GyroSanity folder',
            command = '/bin/mkdir -p ' .. gyrosanity_path
        },
        DebugShell {
            name = 'GyroSanity',
            command = cmd,
            pdca_plist_paths = {pdca_path}
        }
    }
end
