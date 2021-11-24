local ISPFWLogShell = require 'flowextensions.ISPFWLogShell'

return function()
    -- This will generate these samples:
    -- 0 3 6 9 12 15 18 21 24 27 30 60 90 120 150 180 210 240 270 300
    -- 1 time-zero frame + 10 frames at 10Hz + 9 frames at 1Hz = 20 samples
    -- (10 frames at 10Hz = 1s) + (9 frames at 1Hz = 9s) = 10s

    local command = [[
/usr/local/bin/OSDPearlTester ThermalSampling
--test-name ROTherm
--projector romeo-therm
--wait-frames 5
--sample-hz-list "10,1"
--sample-counts-list "10,9"
--csv-path $ASTRO_NODE_LOG_DIRECTORY/frames.csv
--pdca-path $ASTRO_NODE_LOG_DIRECTORY/pdca.plist]]

    return ISPFWLogShell {
        name = "ROTherm",
        description = "Romeo thermal test 10s",
        command = command:gsub("\n", " "),
        timeout = 60,
        pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/pdca.plist"}
    }
end
