local Sequence = require 'flow.Sequence'
local Shell = require 'flow.Shell'

return function(log_path)
    -- Provide a default that can run without a param passed (CLI)
    if log_path == nil then log_path = "$ASTRO_WORKING_DIRECTORY/logs" end

    return Sequence {
        continue_on_fail = true,
        Shell {
            name = 'Create Debug Folder',
            command = '/bin/mkdir -p "' .. log_path .. '"'
        },
        Shell {
            name = 'Copy CrashReporter contents to Debug folder',
            command = '/bin/cp -r /private/var/mobile/Library/Logs/CrashReporter "' .. log_path .. '"'
        }
    }
end
