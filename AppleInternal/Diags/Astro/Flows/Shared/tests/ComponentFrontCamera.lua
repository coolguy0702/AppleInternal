local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'Component Front Camera',
        command = '/usr/local/bin/Component -check frontcamera',
    }
end
