local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'Import Compass Jump Counters',
        description = 'Write accumulated Compass counters from IOReports to PDCA',
        results_name = 'CompassJumpStats',
        command = '/usr/local/bin/HWStatsCollector -softwareName CompassJump -importKeysToPDCAFile YES',
        pdca_plist_paths = {'/private/var/logs/BurnIn/PDCA/_pdca_CompassJump.plist'}
    }
end
