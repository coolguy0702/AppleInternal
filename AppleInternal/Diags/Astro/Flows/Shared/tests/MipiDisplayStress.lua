-- TODO abstract out choosing the train eg Yukon in this example
local DebugShell = require 'flowextensions.DebugShell'
local WithDisplayOn = require 'flowextensions.WithDisplayOn'
local verify = require 'verify'

return function(args)
    local run_offline = false
    local name = 'MIPI Display Stress'

    verify.table(args, 'args should be a table')
    verify.string(args.bundle, 'bundle required and should be string')

    local bundle = args.bundle
    name = name .. ' ' .. bundle

    if args.offline then
        verify.boolean(args.offline, 'offline should be boolean')
        run_offline = args.offline
        if run_offline == true then
            name = name .. ' - Offline'
        end
    end


    local command = string.format('/AppleInternal/Diags/OSScripts/%s/MipiBERStress/script_MipiStress.sh Display "/AppleInternal/Diags/OSScripts/%s/MipiBERStress"', bundle, bundle)

    if run_offline then
        command = string.format('/AppleInternal/Diags/OSScripts/%s/MipiBERStress/script_MipiStress_Offline.sh Display "/AppleInternal/Diags/OSScripts/%s/MipiBERStress"', bundle, bundle)
    end

    local test = DebugShell {
        name = name,
        command = command,
        pdca_plist_paths = {'/var/logs/BurnIn/PDCA/Mipi_BER_Stress_Output.plist'},
        timeout = 7200
    }

    return WithDisplayOn(test)
end
