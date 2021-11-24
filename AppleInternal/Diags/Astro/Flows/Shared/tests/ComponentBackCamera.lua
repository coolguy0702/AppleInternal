local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'Component Back Camera',
        command = '/usr/local/bin/Component -check backcamera',
    }
end
