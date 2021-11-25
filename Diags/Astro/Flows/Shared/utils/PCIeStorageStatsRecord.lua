local DebugShell = require 'flowextensions.DebugShell'

return function(is_incremental)
    local pdca_path = '/private/var/logs/BurnIn/PDCA/_pdca_StoragePcieCheck.plist'
    local command = '/usr/local/bin/HWStatsCollector -softwareName StoragePcieCheck -pdcaOutputPath ' .. pdca_path
    if is_incremental then
        pdca_path = '/private/var/logs/BurnIn/PDCA/_pdca_StoragePcieCheck_incremental.plist'
        command = '/usr/local/bin/HWStatsCollector -softwareName StoragePcieCheck -pdcaOutputPath ' .. pdca_path .. ' -incrementalCheck YES'
    end

    return DebugShell {
        name = "Record PCIe Storage Counters",
        description = "Read PCIe Storage counters for all ports from IOReports",
        results_name = "PCIeStorageStats",
        command = command,
        pdca_plist_paths = {pdca_path}
    }
end
