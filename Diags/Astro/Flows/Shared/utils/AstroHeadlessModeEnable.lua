local Sequence = require "flow.Sequence"
local Condition = require 'flow.classes.Condition'
local If = require 'flow.If'
local verify = require 'verify'
local Shell = require 'flow.Shell'
local Reboot = require "flow.Reboot"

return function(args)
    local should_reboot = true

    if args ~= nil then
        verify.table(args, 'args should be a table')
        if args.should_reboot ~= nil then
            verify.boolean(args.should_reboot, 'should_reboot should be a boolean')
            should_reboot = args.should_reboot
        end
    end

    return Sequence {
        name = 'Enable Astro Headless Default',
        description = 'Enable Astro Headless Default',
        continue_on_fail = false,

        Shell {
            name = 'Enable Astro Headless Default',
            command = '/usr/bin/defaults write com.apple.osdiags.AstroUI headless -bool YES',
            timeout = 30,
        },

        If(Condition('Should reboot', function() return should_reboot end)) {
            Reboot(),
        }
    }
end
