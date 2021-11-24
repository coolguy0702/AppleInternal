local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'GPU Reset Count',
        description = "Read GPU reset count and write it to PDCA",
        results_name = "GPUResetCount",
        command = '/usr/local/bin/OSDGPUTester resetcount',
        pdca_plist_paths = {'/var/logs/BurnIn/PDCA/_pdca_gpuresetcount.plist'}
    }
end
