local PowerTestShell = require 'classes.PowerTestShell'

return function()
    return PowerTestShell {
        name = 'BatteryInstalled',
        command = '/usr/local/bin/BatteryTest -t 1',
    }
end
