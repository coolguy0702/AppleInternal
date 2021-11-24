local PowerTestShell = require 'classes.PowerTestShell'

-- Save battery attributes to a file for reading later
return function()
    return PowerTestShell {
        name = "Save battery attributes",
        command = "/usr/local/bin/BatteryTest -w"
    }
end
