local flowconfig = require 'flowconfig'
local Sequence = require 'flow.Sequence'
local Shell = require 'flow.Shell'
local Step = require 'flow.Step'
local baseband_version = require 'versions.baseband'
local iosdebug = require 'iosdebug'

-- Tar up baseband logs and flag a failure
return function()
    return Sequence {
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        on_enter = {
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
            name = "Check for baseband FW crashes",
            command = "/usr/local/bin/BasebandCrashCheck -d /var/wireless/Library/Logs/CrashReporter/Baseband"
        },
        on_exit = {
            Step {
                name = 'Move baseband crashes to Astro folder',
                description = 'Move BasebandCrashes from BurnIn to Astro folder',

                main = function(self)
                    local after_crashes = iosdebug.baseband.list_baseband_crashes()
                    for _, crash_path in ipairs(after_crashes) do
                        iosdebug.baseband.save_baseband_crash_to_astro(crash_path, self:get_log_dir('BasebandCrashes'), self)
                    end
                end -- End main
            }
        }
    }
end
