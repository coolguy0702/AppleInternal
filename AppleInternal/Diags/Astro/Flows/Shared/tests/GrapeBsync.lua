local flowconfig = require 'flowconfig'
local Sequence = require 'flow.Sequence'
local Step = require 'flow.Step'
local GrapeTestShell = require 'classes.GrapeTestShell'
local grape_version = require 'versions.grape'

return function()
    local pdca_path = '$ASTRO_NODE_LOG_DIRECTORY/_grape_bsync.plist'
    return Sequence {
        ontinue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        on_enter = {
            Step('Save Grape FW version', function (self)
                self:save_software_attributes {
                    grape_firmware_version = grape_version()
                }
            end)
        },

        GrapeTestShell {
            name = 'Grape BSYNC Count',
            results_name = 'GrapeBSYNCCount',
            command = '/usr/local/bin/OSDComponent grape_bsync --pdcaPath=' .. pdca_path,
            pdca_plist_paths = {pdca_path}
        }
    }
end
