-- <rdar://problem/47957065> J3xx: Add parametric key for BCDW at BurnIn and MMI
-- BCDW detects cell disconnects which we believe to be caused by faulty gas gauge readings.
-- BCDW is _not_ sticky between reboots

local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
            name = 'Battery Cell Disconnect Waive Count',
            results_name = 'BatteryCellDisconnectWaiveCount',
            command = '/usr/local/bin/OSDBatteryTester BCDW --upperBCDWLimit 0',
            timeout = 60,
            pdca_plist_paths = {'/var/logs/BurnIn/PDCA/_battery_bcdw.plist'},
    }
end
