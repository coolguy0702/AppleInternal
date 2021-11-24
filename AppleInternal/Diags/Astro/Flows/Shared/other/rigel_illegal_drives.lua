local FactoryStation = require 'manufacturing.FactoryStation'
local CameraUnitInfo = require 'info.CameraUnitInfo'
local RigelIllegalDrive = require 'tests.pearl.RigelIllegalDrive'

gFLOW_CONFIG = {
    continue_on_fail = true,
}

return FactoryStation {
    station = "OFFLINE-BURNIN",
    continue_on_fail = gFLOW_CONFIG.continue_on_fail,

    RigelIllegalDrive(),
    CameraUnitInfo(), -- consumes a token if there is one
}
