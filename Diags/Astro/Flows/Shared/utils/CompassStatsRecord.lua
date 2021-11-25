local DebugShell = require 'flowextensions.DebugShell'

return function(is_incremental)
    local pdca_file = '/private/var/logs/BurnIn/PDCA/_pdca_CompassCheck.plist'

    if is_incremental then
        pdca_file = '/private/var/logs/BurnIn/PDCA/_pdca_incremental_CompassCheck.plist'
    end

    local command = '/usr/local/bin/HWStatsCollector -softwareName CompassJump -pdcaOutputPath ' .. pdca_file

    local name = 'Record Compass Stats'
    if is_incremental then
        command = command .. ' -incrementalCheck YES'
        name = name .. ' (Incremental)'
    end

    return DebugShell {
        name = name,
        description = 'Read Compass counters from IOReports',
        results_name = 'CompassJumpStats',
        command = command,
        pdca_plist_paths = {pdca_file}
    }
end
