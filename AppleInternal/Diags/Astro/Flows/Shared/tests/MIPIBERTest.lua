local MipiFileCleanupShell = require 'classes.MipiFileCleanupShell'
local WithDisplayOn = require 'flowextensions.WithDisplayOn'

return function(runOffline)
    local arg = 'online'
    local pdcaResultPath = '/private/var/logs/BurnIn/PDCA/MIPI_BurninTestOnline.plist'
    if runOffline then
        arg = 'offline'
        pdcaResultPath = '/private/var/logs/BurnIn/PDCA/MIPI_BurninTestOffline.plist'
    end

    local test = MipiFileCleanupShell {
        name = 'MIPIBERTest',
        command = '/AppleInternal/Diags/OSScripts/Yukon/EE_ISP_Scripts/h10_mipi_test.sh ' .. arg,
        pdca_plist_paths = {pdcaResultPath},
        timeout = 3600
    }

    return WithDisplayOn(test)
end
