local FactoryStation = require 'manufacturing.FactoryStation'
local Loop = require 'flow.Loop'
local Reboot = require 'flow.Reboot'
local Sleep = require 'flow.Sleep'

-- info
local TGraphEnable = require 'info.tgraph.Enable'
local TGraphDisable = require 'info.tgraph.Disable'

-- utils
local CopyAstroDebug = require 'utils.CopyAstroDebug'

local PhosOrbAggressors = require 'tests.PhosOrbAggressors'
local ComponentPhosOrb = require 'tests.ComponentPhosOrb'
local ComponentGrapeCriticalError = require 'tests.ComponentGrapeCriticalError'
local GrapeResets = require 'tests.GrapeResets'

gFLOW_CONFIG = {
    continue_on_fail = true
}

local cycle_count = 20
return FactoryStation {
    station = "OFFLINE-BURNIN",
    continue_on_fail = true,

    TGraphEnable(),
    PhosOrbAggressors(),
    Loop(cycle_count) {
        name = 'RebootLoop x' .. cycle_count,
        results_name = 'RebootLoop',
        description = cycle_count .. "x reboot cycle(s)",
        continue_on_fail = gFLOW_CONFIG.continue_on_fail,

        Reboot(),
        ComponentPhosOrb(),
        ComponentGrapeCriticalError(),
        GrapeResets(),
    },

    Loop(cycle_count) {
        name = 'SleepLoop x' .. cycle_count,
        results_name = 'SleepLoop',
        description = cycle_count .. "x sleep cycle(s)",
        continue_on_fail = gFLOW_CONFIG.continue_on_fail,

        Sleep(10), -- Sleep for 10s
        ComponentPhosOrb(),
        ComponentGrapeCriticalError(),
        GrapeResets(),

        TGraphDisable(), -- rdar://problem/45897719
        CopyAstroDebug(),
    }
}
