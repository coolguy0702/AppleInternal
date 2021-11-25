local DebugShell = require 'flowextensions.DebugShell'

return function(is_incremental)
    local command = '/usr/local/bin/HWStatsCollector -softwareName PcieCheck -pdcaOutputPath /private/var/logs/BurnIn/PDCA/_pdca_PcieCheck.plist'
    local pdca_file = '/private/var/logs/BurnIn/PDCA/_pdca_PcieCheck.plist'

    if is_incremental then
        command = '/usr/local/bin/HWStatsCollector -softwareName PcieCheck -pdcaOutputPath /private/var/logs/BurnIn/PDCA/_pdca_incremental_PcieCheck.plist -incrementalCheck YES'
        pdca_file = '/private/var/logs/BurnIn/PDCA/_pdca_incremental_PcieCheck.plist'
    end

    return DebugShell {
        name = "Record PCIe Counters",
        description = "Read PCIe counters for all ports from IOReports",
        results_name = "PCIeStats",
        command = command,
        pdca_plist_paths = {pdca_file}
    }
end
