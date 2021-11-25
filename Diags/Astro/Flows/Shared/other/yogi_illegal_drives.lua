local FactoryStation = require 'manufacturing.FactoryStation'
local CameraUnitInfo = require 'info.CameraUnitInfo'
local YogiIllegalDrive = require 'tests.pearl.YogiIllegalDrive'

gFLOW_CONFIG = {
    continue_on_fail = true,
}

return FactoryStation {
    station = "OFFLINE-BURNIN",
    continue_on_fail = gFLOW_CONFIG.continue_on_fail,

    YogiIllegalDrive(),
    CameraUnitInfo(), -- consumes a token if there is one
}
