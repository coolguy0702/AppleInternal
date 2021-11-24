local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'Component LCD',
        command = '/usr/local/bin/Component -check lcd',
    }
end
