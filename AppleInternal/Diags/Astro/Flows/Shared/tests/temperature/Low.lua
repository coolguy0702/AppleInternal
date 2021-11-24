local DebugShell = require "flowextensions.DebugShell"

return function()
    return DebugShell {
        name = "iOS Temperature Low",
        command = "/AppleInternal/Diags/OSScripts/ThermalScripts/iOS_Online_thermalVirus_low.pl", -- TODO: rdar://problem/46049675
        pdca_plist_paths = {"/private/var/logs/BurnIn/PDCA/_pdca_thermal_low.plist"}
    }
end
