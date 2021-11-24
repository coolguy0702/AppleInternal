local Sequence = require "flow.Sequence"
local Step = require 'flow.Step'
local Shell = require 'flow.Shell'
local Reboot = require "flow.Reboot"
local flowconfig = require 'flowconfig'
local epcall = require 'exceptions.epcall'
local fs = require 'filesystem'

return function()
    return Sequence {
        name = 'Disable Sysdiagnose',
        description = 'Disable sysdiagnose and delete all existing sysdiagnose files',
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        Shell {
            name = 'Disable Sysdiagnose',
            command = '/usr/bin/defaults write com.apple.sysdiagnose factoryDisable -bool YES',
            timeout = 30,
        },

        Reboot(),

        Step {
            name = 'Delete all existing sysdiagnose files',
            description = 'Delete all existing sysdiagnose files',
            main = function()
                local path = '/private/var/mobile/Library/Logs/CrashReporter/DiagnosticLogs/sysdiagnose'
                local success, err = epcall(function ()
                    fs.remove(path)
                end)

                if not success then
                    print('Folder ' .. path ..' does not exist or there is an error while removing: ' .. err.message)
                end
            end
        }
    }
end
