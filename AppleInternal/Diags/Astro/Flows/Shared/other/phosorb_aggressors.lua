local FactoryStation = require 'manufacturing.FactoryStation'
local PhosOrbAggressors = require 'tests.PhosOrbAggressors'

-- info
local TGraphEnable = require 'info.tgraph.Enable'
local TGraphDisable = require 'info.tgraph.Disable'

-- utils
local CopyAstroDebug = require 'utils.CopyAstroDebug'

gFLOW_CONFIG = {continue_on_fail = true} -- global

return FactoryStation {
    station = "OFFLINE-BURNIN",
    continue_on_fail = true,

    TGraphEnable(),
    PhosOrbAggressors(),

    on_exit = {
        TGraphDisable(), -- rdar://problem/45897719
        CopyAstroDebug(),
    }
}
