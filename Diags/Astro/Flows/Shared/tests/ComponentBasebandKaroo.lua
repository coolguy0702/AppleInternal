local Sequence = require 'flow.Sequence'
local BasebandShell = require 'classes.BasebandShell'
local Step = require 'flow.Step'
local BasebandReady = require 'utils.BasebandReady'
local time = require 'time'
local flowconfig = require 'flowconfig'
local baseband_version = require 'versions.baseband'

return function()
    return Sequence {
        name = "Component Baseband",
        description = "Enable remote wake to exercise PCIe sleep states, check baseband is alive",
        results_name = "Component Baseband",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        on_enter = {
            BasebandReady(20),
            Step {
                name = 'Save Baseband FW version',
                description = 'Save Baseband FW version',
                main = function(self)
                    self:save_software_attributes {
                        baseband_firmware_version = baseband_version()
                    }
                end
            },
        },
        BasebandShell {
            name = 'Enable BB remote wake 500ms', -- TODO: WHY
            command = '/usr/local/bin/KTLTool --nolibtu -v --timeoutMs=7500 bsp_set_ap_wake 1 500', -- Enable BB remote wake each 500ms
            timeout = 30
        },
        Step {
            name = 'Sleep 5',
            description = 'Wait for remote wake toggles',
            main = function()
                time.sleep(5)
            end
        },
        BasebandReady(20), -- need to make sure BB is up so we can run KTLTool
        BasebandShell {
            name = 'Disable BB remote wake', -- TODO: WHY
            command = '/usr/local/bin/KTLTool --nolibtu -v --timeoutMs=7500 bsp_set_ap_wake 0 1',
            timeout = 30
        },
        BasebandShell {
            name = 'Component Baseband', -- TODO: WHY
            command = '/usr/local/bin/Component -check telephonybaseband',
        },
    }
end
