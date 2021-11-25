-- <rdar://problem/44950345> J3xx: Add checks for BCDC (Cell Disconnect Count) and BCDD (Cell Disconnect detected)
-- BCDC _is_ sticky between reboots
local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
            name = 'Battery Cell Disconnected Count',
            results_name = 'BatteryCellDisconnectedCount',
            command = '/usr/local/bin/OSDBatteryTester BCDC',
            timeout = 60,
            pdca_plist_paths = {'/var/logs/BurnIn/PDCA/_battery_bcdc.plist'},
    }
end
