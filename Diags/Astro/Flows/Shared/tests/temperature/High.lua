local DebugShell = require "flowextensions.DebugShell"

return function()
    return DebugShell {
        name = "iOS Temperature High",
        command = "/AppleInternal/Diags/OSScripts/ThermalScripts/iOS_Online_thermalVirus_high.pl", -- TODO: rdar://problem/46049675
        pdca_plist_paths = {"/private/var/logs/BurnIn/PDCA/_pdca_thermal_high.plist"}
    }
end
