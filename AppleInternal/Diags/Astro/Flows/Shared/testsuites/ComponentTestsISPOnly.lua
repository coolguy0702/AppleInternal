local If = require 'flow.If'
local Sequence = require 'flow.Sequence'
local Condition = require 'flow.classes.Condition'
local ComponentPearlTests = require 'testsuites.ComponentPearlTests'
local ComponentCameraTests = require 'testsuites.ComponentCameraTests'
local flowconfig = require 'flowconfig'

return function(args)
    return Sequence {
        name = "ISP component test suite",
        description = "ISP component test suite",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        If(Condition("Run Pearl Tests", function() return args.enable_pearl_tests end)) {
            continue_on_fail = flowconfig.getglobal('continue_on_fail', true),
            ComponentPearlTests(),
        },
        ComponentCameraTests(),
    }
end
