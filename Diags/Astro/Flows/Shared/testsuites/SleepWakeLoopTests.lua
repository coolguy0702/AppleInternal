local Loop              = require 'flow.Loop'
local WakeOnSPU         = require 'tests.sleepwake.WakeOnSPU'
local WakeOnWifi        = require 'tests.sleepwake.WakeOnWifi'
local WakeOnBluetooth   = require 'tests.sleepwake.WakeOnBluetooth'
local WakeOnBaseband    = require 'tests.sleepwake.WakeOnBaseband'
local WakeOnStockholm   = require 'tests.sleepwake.WakeOnStockholm'

local flowconfig        = require 'flowconfig'

return function(cycle_count, desc)
    cycle_count = cycle_count or 1
    -- add ": Desc" if provided
    desc = desc and " " .. desc or ""

    return Loop(cycle_count) {
        name = 'SleepWakeLoop x' .. cycle_count .. desc,
        results_name = 'SleepWakeLoop' .. desc,
        description = cycle_count .. "x sleep wake cycle(s)" .. desc,
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        WakeOnSPU(),
        WakeOnWifi(),
        WakeOnBluetooth(),
        WakeOnBaseband(),
        WakeOnStockholm(),
    }
end
