local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'Component Turtle',
        command = '/usr/local/bin/Component -check turtle',
        timeout = 30,
    }
end
