local BaneTherm20s = require 'tests.pearl.BaneTherm20s'
local BaneCoex20s = require 'tests.pearl.BaneCoex20s'
local PearlTherm10m = require 'tests.pearl.PearlTherm10m'
local RomeoTherm = require 'tests.pearl.RomeoTherm'

local Reboot = require 'flow.Reboot'
local Sequence = require 'flow.Sequence'
local Step = require 'flow.Step'

local time = require 'time'
local flowconfig = require 'flowconfig'

-- thermal tests should start relatively cool on CG/forehead
return function()
    return Sequence {
        description = "Projector rel tests",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        RomeoTherm(),

        BaneCoex20s(),
        Reboot(),
        BaneTherm20s(),

        Step {
            name = "Pearl Thermal Dwell",
            description = "Pearl Thermal Dwell 1m",
            main = function()
                time.sleep(60)
            end
        },

        PearlTherm10m(),
    }
end
