local Shell = require 'flow.Shell'

return function()
    return Shell {
        name = 'Enable shutdown view',
        command = '/usr/bin/defaults write com.apple.osdiags.AstroUI enable-shutdown-view -bool YES'
    }
end
