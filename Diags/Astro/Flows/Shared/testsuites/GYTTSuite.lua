local flowconfig = require 'flowconfig'
local Sequence = require 'flow.Sequence'

local GenerateGyroTemperatureTable = require 'tests.GenerateGyroTemperatureTable'
local PCIeStatsRecord = require 'utils.PCIeStatsRecord'
local WifiStress = require 'classes.WifiStress'

return function()
    return Sequence {
        name = 'GYTT Suite',
        description = 'GYTT Suite',
        results_name = 'GYTTSuite',
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        WifiStress {
            iteration_count = 1250,
            run_prepost_test = false,
            timeout = 1000,
            child = GenerateGyroTemperatureTable()
        },
        PCIeStatsRecord(false)
    }
end
