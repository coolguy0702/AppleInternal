local MipiFileCleanupShell = require 'classes.MipiFileCleanupShell'
local WithDisplayOn = require 'flowextensions.WithDisplayOn'

return function(run_offline)
    local arg = 'online'
    local pdcaResultPath = '/private/var/logs/BurnIn/PDCA/LPDP_BurninTestOnline.plist'
    if run_offline then
        arg = 'offline'
        pdcaResultPath = '/private/var/logs/BurnIn/PDCA/LPDP_BurninTestOffline.plist'
    end

    local test = MipiFileCleanupShell {
        name = 'LPDPBERTest',
        command = '/AppleInternal/Diags/OSScripts/Yukon/EE_ISP_Scripts/h10_lpdp_test.sh ' .. arg,
        pdca_plist_paths = {pdcaResultPath},
        timeout = 3600
    }

    return WithDisplayOn(test)
end
