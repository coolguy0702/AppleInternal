local FactoryStation = require 'manufacturing.FactoryStation'

-- info
local TGraphEnable = require 'info.tgraph.Enable'
local TGraphDisable = require 'info.tgraph.Disable'
local SaveDebugLogs = require 'info.SaveDebugLogs'

-- utils
local CopyAstroDebug = require 'utils.CopyAstroDebug'

-- tests
local GenerateGyroTemperatureTable = require 'tests.GenerateGyroTemperatureTable'

gFLOW_CONFIG = {continue_on_fail = true} -- global

return FactoryStation {
    station = "OFFLINE-BURNIN",
    continue_on_fail = true,

    TGraphEnable(),
    SaveDebugLogs('$ASTRO_WORKING_DIRECTORY/logs/InitialDebugLogs'),
    GenerateGyroTemperatureTable(),
    on_exit = {
        TGraphDisable(),
        SaveDebugLogs('$ASTRO_WORKING_DIRECTORY/logs/EndDebugLogs'),
        CopyAstroDebug(),
    },
}
