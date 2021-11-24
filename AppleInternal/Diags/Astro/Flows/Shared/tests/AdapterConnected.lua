local PowerTestShell = require 'classes.PowerTestShell'

return function()
    return PowerTestShell {
        name = 'AdapterConnected',
        command = '/usr/local/bin/BatteryTest -t 6 -T 30',
    }
end
