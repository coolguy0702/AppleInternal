local flowconfig = require 'flowconfig'
local Sequence = require 'flow.Sequence'
local Step = require 'flow.Step'
local DebugShell = require 'flowextensions.DebugShell'
local spu_version = require 'versions.spu'

return function()
    return Sequence {
        ontinue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        on_enter = {
            Step('Save SPU FW version', function (self)
                self:save_software_attributes {
                    spu_firmware_version = spu_version()
                }
            end)
        },
        DebugShell {
            name = 'Component SPU',
            command = '/usr/local/bin/Component -check spu',
        }
    }
end
