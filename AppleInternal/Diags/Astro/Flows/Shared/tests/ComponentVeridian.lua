local AuthDebugShell = require "classes.AuthDebugShell"
local Condition = require "flow.classes.Condition"
local If = require "flow.If"
local processutils = require "processutils"



local should_run_test = function()
    local vcrt_exists_result = processutils.shell('/usr/local/bin/OSDToolbox FDR -k vcrt --AMFDRSealingMapCopy', 30)
    local entitlement_exists_result = processutils.shell('/usr/local/bin/OSDToolbox apticket -e facf', 30)

    print('vcrt_exists code = ' .. vcrt_exists_result.code .. ', entitlement_exists code = ' .. entitlement_exists_result.code)

    if vcrt_exists_result.code ~= 0 and entitlement_exists_result.code == 0 then
        print('Claim once entitlement exists and vcrt does not exist, not running Veridian test')
        return false
    else
        print('Running Veridian test')
        return true
    end
end



return function(should_reauth)
    local pdca_path = "/tmp/roswell_pdca.plist"
    local auth_node

    if should_reauth then
        auth_node = AuthDebugShell {
            name = "Component Veridian (ReAuth)",
            results_name = "ComponentVeridianReAuth",
            command =  "/usr/local/bin/OSDRoswell auth --reauth --label Sleep --accessory battery --retries 3 --quiesce 1 --pdcaPath " .. pdca_path,
            pdca_plist_paths = {pdca_path},
            timeout = 30,
            fdr_key = "vcrt"
        }
    else
        auth_node = AuthDebugShell {
            name = "Component Veridian",
            results_name = "ComponentVeridian",
            command =  "/usr/local/bin/OSDRoswell auth --label Reboot --accessory battery --retries 3 --quiesce 1 --pdcaPath " .. pdca_path,
            pdca_plist_paths = {pdca_path},
            timeout = 30,
            fdr_key = "vcrt"
        }
    end

    return If(Condition(should_run_test, 'Allow Claim Entitlement does not exist')) {
        name = "Veridian auth and fdr validation",
        continue_on_fail = false,

        auth_node,

        AuthDebugShell {
            name = "Veridian FDR Validation",
            results_name = "VeridianFDR",
            command = "/usr/local/bin/OSDRoswell fdrval --accessory battery",
            timeout = 30,
            fdr_key = "vcrt"
        },
        AuthDebugShell {
            name = "Veridian Trusted",
            results_name = "VeridianTrusted",
            command = "/usr/local/bin/OSDRoswell trusted --accessory battery",
            timeout = 30,
            fdr_key = "vcrt"
        }
    }
end
