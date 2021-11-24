local DebugShell = require 'flowextensions.DebugShell'

return function()
    local pdca_path = '/private/var/logs/BurnIn/PDCA/_pdca_StoragePcieCheck.plist'
    return DebugShell {
        name = "Write accumulated PCIe Counters to PDCA",
        description = "Import accumulated PCIe Storage counters for all ports from IOReports",
        results_name = "PCIeStorageStats",
            command = '/usr/local/bin/HWStatsCollector -softwareName StoragePcieCheck -importKeysToPDCAFile YES -pdcaOutputPath ' .. pdca_path,
        pdca_plist_paths = {pdca_path}
    }
end
