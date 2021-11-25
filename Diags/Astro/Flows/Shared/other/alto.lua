local FactoryStation = require 'manufacturing.FactoryStation'
local AltoMobile = require 'tests.AltoMobile'

return FactoryStation {
    station = "OFFLINE-BURNIN",
    description = "Alto BurnIn",

    AltoMobile(),
}
