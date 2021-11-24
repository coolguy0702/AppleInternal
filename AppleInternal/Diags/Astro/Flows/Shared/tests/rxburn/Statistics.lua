local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = 'RXBurn statistics',
        command = '/usr/local/bin/RxBurnTester -d',
        timeout = 30
    }
end
