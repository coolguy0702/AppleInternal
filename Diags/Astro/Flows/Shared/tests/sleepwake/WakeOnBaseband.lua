local Sequence = require 'flow.Sequence'
local Step = require 'flow.Step'
local DebugShell = require 'flowextensions.DebugShell'
local BasebandReady = require 'utils.BasebandReady'
local baseband_version = require 'versions.baseband'

return function()
    return Sequence {
        on_enter = {
            BasebandReady(20),
            Step {
                name = 'Save Baseband FW version',
                main = function(self)
                    self:save_software_attributes {
                        baseband_firmware_version = baseband_version()
                    }
                end
            },
        },

        DebugShell {
            name = 'Wake On Baseband',
            command = '/usr/local/bin/OSDWakeOn -t basebanddeepsleep  -r 5 -R 5 -b 30 -a true',
            timeout = 100
        },
    }
end
