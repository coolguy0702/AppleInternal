local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'Component Lynx',
        command = '/usr/local/bin/OSDLynx lynb',
    }
end
