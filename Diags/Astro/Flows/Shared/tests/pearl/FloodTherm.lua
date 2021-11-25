local ISPFWLogShell = require 'flowextensions.ISPFWLogShell'

return function()
    return ISPFWLogShell {
        name = "FloodTherm",
        description = "Flood thermal test 20s",
        command = '/usr/local/bin/OSDPearlTester ThermalSampling --test-name FloodTherm --projector rosa-therm --wait-frames 5 --sample-hz-list "10,1" --sample-counts-list "20,18" --too-hot-ntc 55.5 --csv-path $ASTRO_NODE_LOG_DIRECTORY/frames.csv --pdca-path $ASTRO_NODE_LOG_DIRECTORY/pdca.plist',
        timeout = 60,
        pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/pdca.plist"}
    }
end
