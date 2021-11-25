local FactoryStation = require 'manufacturing.FactoryStation'
local RxBurnStart = require 'tests.rxburn.Start'
local RxBurnPause = require 'tests.rxburn.Pause'
local RxBurnResume = require 'tests.rxburn.Resume'
local RxBurnProgress = require 'tests.rxburn.Progress'
local RxBurnComplete = require 'tests.rxburn.Complete'
local RxBurnStatistics = require 'tests.rxburn.Statistics'
local ASPDataImport = require 'tests.ASPDataImport'

return FactoryStation {
    station = "OFFLINE-BURNIN",
    on_enter = {
        RxBurnResume()
    },

    RxBurnStatistics(),
    RxBurnStart(),
    RxBurnPause(),
    RxBurnPause(),
    RxBurnProgress(),
    RxBurnResume(),
    RxBurnResume(),
    RxBurnProgress(),

    on_exit = {
        RxBurnComplete(),
        ASPDataImport(),
    },
}
