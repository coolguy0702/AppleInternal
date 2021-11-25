local ISPFWLogShell = require 'flowextensions.ISPFWLogShell'
local If = require 'flow.If'
local Condition = require 'flow.classes.Condition'
local Step = require 'flow.Step'
local Sequence = require 'flow.Sequence'
local device = require 'device'

return function()
    return Sequence {
        name = "Rosaline/Vader decision sequence",
        continue_on_fail = true, -- Must hard-code to true to get if-else behavior

        If(Condition("Rosaline", function() return not device.has_vader() end)) {
            -- This will generate these samples:
            -- 0 3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 90 120 150 180
            -- 210 240 270 300 330 360 390 420 450 480 510 540 570 600
            -- 1 time-zero frame + 20 frames at 10Hz + 18 frames at 1Hz = 39 samples
            -- (20 frames at 10Hz = 2s) + (10 frames at 1Hz = 18s) = 20s

            ISPFWLogShell {
                name = "RSTherm",
                description = "Rosaline thermal test 20s",
                command = '/usr/local/bin/OSDPearlTester ThermalSampling --test-name RSTherm --projector rosa-therm --wait-frames 5 --sample-hz-list "10,1" --sample-counts-list "20,18" --too-hot-ntc 55.5 --csv-path $ASTRO_NODE_LOG_DIRECTORY/frames.csv --pdca-path $ASTRO_NODE_LOG_DIRECTORY/pdca.plist',
                timeout = 60,
                pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/pdca.plist"}
            }
        },

        If(Condition("Vader", function() return device.has_vader() end)) {
            Step(
                "Fail Vader",
                function(self)
                    self:save_passfail_result {
                        name = "HasVader",
                        pass = false,
                        message = "Device has Vader",
                    }
                end
            )
        }
    }
end
