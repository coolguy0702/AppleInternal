local AuthDebugShell = require "classes.AuthDebugShell"
local Sequence = require "flow.Sequence"



return function(should_reauth)
    local pdca_path = "/tmp/roswell_pdca.plist"
    local auth_node

    if should_reauth then
        auth_node = AuthDebugShell {
            name = "Component Roswell Touch (ReAuth)",
            results_name = "ComponentRoswellTouchReAuth",
            command =  "/usr/local/bin/OSDRoswell auth --reauth --label Sleep --accessory touch --retries 3 --quiesce 1 --pdcaPath " .. pdca_path,
            pdca_plist_paths = {pdca_path},
            timeout = 30,
            fdr_key = "tcrt"
        }
    else
        auth_node = AuthDebugShell {
            name = "Component Roswell Touch",
            results_name = "ComponentRoswellTouch",
            command =  "/usr/local/bin/OSDRoswell auth --label Reboot --accessory touch --retries 3 --quiesce 1 --pdcaPath " .. pdca_path,
            pdca_plist_paths = {pdca_path},
            timeout = 30,
            fdr_key = "tcrt"
        }
    end

    return Sequence {
        name = "Roswell touch auth and fdr validation",
        continue_on_fail = false,

        auth_node,

        AuthDebugShell {
            name = "Roswell Touch FDR Validation",
            results_name = "RoswellTouchFDRVal",
            command = "/usr/local/bin/OSDRoswell fdrval --accessory touch",
            timeout = 30,
            fdr_key = "tcrt"
        },

        AuthDebugShell {
            name = "Roswell Touch Trusted",
            results_name = "RoswellTouchTrusted",
            command = "/usr/local/bin/OSDRoswell trusted --accessory touch",
            timeout = 30,
            fdr_key = "tcrt"
        }
    }
end
