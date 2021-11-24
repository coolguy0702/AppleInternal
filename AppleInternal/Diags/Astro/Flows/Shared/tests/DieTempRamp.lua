local Sequence = require 'flow.Sequence'
local DebugShell = require 'flowextensions.DebugShell'
local WithDisplayOn = require 'flowextensions.WithDisplayOn'

-- This test will heat up the device and record delta heating. Device must be at low temperature to run this.
return function()
    local pdca_path = '$ASTRO_NODE_LOG_DIRECTORY/die_temp_ramp.plist'
    local test = Sequence {
        on_enter = {
            DebugShell {
                name = 'Brightness 50%',
                command = '/usr/local/bin/BacklightdTester -set DisplayBrightness 0.5',
                timeout = 30
            }
        },
        DebugShell {
            name = 'Die Temp Ramp Test',
            results_name = 'DieTempRamp',
            command = '/usr/local/bin/OSDThermalTool cpuJump -n DieTempRampTest --pdcaPath=' .. pdca_path,
            pdca_plist_paths = {pdca_path}
        }
    }

    return WithDisplayOn(test)
end
