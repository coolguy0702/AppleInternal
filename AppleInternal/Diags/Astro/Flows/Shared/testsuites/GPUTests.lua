local flowconfig        = require 'flowconfig'
local Sequence          = require 'flow.Sequence'
local GPUConformance    = require 'tests.GPUConformance'
local DysonTrace        = require 'tests.DysonTrace'
local Fugue             = require 'tests.Fugue'
local GPUResetCount     = require 'tests.GPUResetCount'

return function()
    return Sequence {
        name = 'GPU test suite',
        description = 'GPU test suite',
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        GPUConformance(),
        DysonTrace(),
        Fugue(),
        GPUResetCount()
    }

end
