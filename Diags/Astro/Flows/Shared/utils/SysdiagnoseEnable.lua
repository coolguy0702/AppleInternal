local Shell = require 'flow.Shell'

return function()
    return Shell {
        name = 'Enable Sysdiagnose',
        command = '/usr/bin/defaults write com.apple.sysdiagnose factoryDisable -bool NO',
    }
end
