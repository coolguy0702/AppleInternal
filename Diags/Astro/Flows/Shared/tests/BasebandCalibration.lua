local Sequence = require 'flow.Sequence'
local Shell = require 'flow.Shell'
local Step = require 'flow.Step'
local BasebandReady = require 'utils.BasebandReady'
local baseband_version = require 'versions.baseband'

return function()
    return Sequence {
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

        Shell {
            name = 'Check if BB has calibration',
            command = 'bbCalStatus=`/usr/local/bin/KTLTool bsp_get_calib_status`; echo "${bbCalStatus}"; echo $bbCalStatus | /usr/bin/grep -A 5 -B 5 "CSI_ICE_BSP_CALIBRATED"',
            timeout = 30
        }
    }
end
