local AuthDebugShell = require "classes.AuthDebugShell"
local Sequence = require "flow.Sequence"



return function(should_reauth)
    local pdca_path = "/tmp/roswell_pdca.plist"
    local auth_node

    if should_reauth then
        auth_node = AuthDebugShell {
            name = "Component Roswell Battery (ReAuth)",
            results_name = "ComponentRoswellBatteryReAuth",
            command =  "/usr/local/bin/OSDRoswell auth --reauth --label Sleep --accessory battery --retries 3 --quiesce 1 --pdcaPath " .. pdca_path,
            pdca_plist_paths = {pdca_path},
            timeout = 30,
            fdr_key = "bcrt"
        }
    else
        auth_node = AuthDebugShell {
            name = "Component Roswell Battery (ReAuth)",
            results_name = "ComponentRoswellBatteryReAuth",
            command =  "/usr/local/bin/OSDRoswell auth --label Reboot --accessory battery --retries 3 --quiesce 1 --pdcaPath " .. pdca_path,
            pdca_plist_paths = {pdca_path},
            timeout = 30,
            fdr_key = "bcrt"
        }
    end

    return Sequence {
        name = "Roswell battery auth and fdr validation",
        continue_on_fail = false,

        auth_node,

        AuthDebugShell {
            name = "Roswell Battery FDR Validation",
            results_name = "RoswellBattFDRVal",
            command = "/usr/local/bin/OSDRoswell fdrval --accessory battery",
            timeout = 30,
            fdr_key = "bcrt"
        },

        AuthDebugShell {
            name = "Roswell Battery Trusted",
            results_name = "RoswellBattTrusted",
            command = "/usr/local/bin/OSDRoswell trusted --accessory battery",
            timeout = 30,
            fdr_key = "bcrt"
        }
    }
end
