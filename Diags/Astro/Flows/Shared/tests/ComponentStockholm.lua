local flowconfig = require 'flowconfig'
local Sequence = require 'flow.Sequence'
local Step = require 'flow.Step'
local DebugShell = require 'flowextensions.DebugShell'
local stockholm_version = require 'versions.stockholm'

return function()
    return Sequence {
        ontinue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        on_enter = {
            Step {
                name = 'Save Stockholm FW version',
                main = function(self)
                    self:save_software_attributes {
                        stockholm_firmware_version = stockholm_version()
                    }
                end
            },
        },
        DebugShell {
            name = "ComponentStockholm",
            command = '/usr/local/bin/Component -check stockholm',
            timeout = 30
        }
    }
end
