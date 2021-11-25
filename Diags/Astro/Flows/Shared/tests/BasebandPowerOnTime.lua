local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'Baseband Power On Time',
        results_name = 'Baseband-PowerOnTime',
        command = '/usr/local/bin/BasebandTest -t powerontime -l 50.0 -p $ASTRO_WORKING_DIRECTORY/_pdca_baseband_poweron.plist',
        pdca_plist_paths = {'$ASTRO_WORKING_DIRECTORY/_pdca_baseband_poweron.plist'}
    }

end
