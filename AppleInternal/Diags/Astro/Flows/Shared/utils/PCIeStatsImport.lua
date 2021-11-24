local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'Import PCIe Counters',
        description = "Write accumulated PCIe counters for all ports from IOReports to PDCA",
        results_name = "PCIeStats",
        command = '/usr/local/bin/HWStatsCollector -softwareName PcieCheck -importKeysToPDCAFile YES',
        pdca_plist_paths = {'/private/var/logs/BurnIn/PDCA/_pdca_PcieCheck.plist'}
    }
end
