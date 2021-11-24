local flowconfig = require 'flowconfig'
local Sequence = require 'flow.Sequence'
local Step = require 'flow.Step'
local GrapeTestShell = require 'classes.GrapeTestShell'
local grape_version = require 'versions.grape'

return function()
    return Sequence {
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        on_enter = {
            Step('Save Grape FW version', function (self)
                self:save_software_attributes {
                    grape_firmware_version = grape_version()
                }
            end)
        },

        GrapeTestShell {
            name = 'Component Grape Critical Errors',
            command = '/usr/local/bin/OSDComponent grape_critical_error',
        }
    }
end
