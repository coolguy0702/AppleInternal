local FactoryStation = require 'manufacturing.FactoryStation'
local CameraUnitInfo = require 'info.CameraUnitInfo'
local RomeoTherm = require 'tests.pearl.RomeoTherm'
local RosalineTherm = require 'tests.pearl.RosalineTherm'
local PearlTherm2m = require 'tests.pearl.PearlTherm2m'

return FactoryStation {
    station = "OFFLINE-BURNIN",
    continue_on_fail = true,

    CameraUnitInfo(),

    RomeoTherm(),
    RosalineTherm(),
    PearlTherm2m(),
}
