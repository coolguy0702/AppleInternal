local FactoryStation = require 'manufacturing.FactoryStation'
local CameraUnitInfo = require 'info.CameraUnitInfo'
local ComponentPearlTests = require 'testsuites.ComponentPearlTests'
local RigelIllegalDrive = require 'tests.pearl.RigelIllegalDrive'
local YogiIllegalDrive = require 'tests.pearl.YogiIllegalDrive'
local RomeoTherm = require 'tests.pearl.RomeoTherm'
local RosalineTherm = require 'tests.pearl.RosalineTherm'

gFLOW_CONFIG = {
    continue_on_fail = true,
}

return FactoryStation {
    station = "OFFLINE-BURNIN",
    continue_on_fail = gFLOW_CONFIG.continue_on_fail,

    CameraUnitInfo(),
    ComponentPearlTests(),
    RigelIllegalDrive(),
    YogiIllegalDrive(),
    RomeoTherm(),
    RosalineTherm(),
}
