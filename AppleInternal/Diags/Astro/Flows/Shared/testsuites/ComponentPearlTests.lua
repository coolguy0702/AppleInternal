local flowconfig = require 'flowconfig'
local Sequence  = require 'flow.Sequence'
local ComponentYogi = require 'tests.pearl.ComponentYogi'
local ComponentRigel = require 'tests.pearl.ComponentRigel'
local ComponentMamaBear = require 'tests.pearl.ComponentMamaBear'

return function()
    return Sequence {
        description = "Pearl component check test suite",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        ComponentYogi(),
        ComponentRigel(),
        ComponentMamaBear(),
    }
end
