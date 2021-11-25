local PowerTestShell = require 'classes.PowerTestShell'

return function(battery_percentage)
    -- Default so we can run from the CLI
    if not battery_percentage then battery_percentage = 10 end

    return PowerTestShell {
        name = 'Ensure battery at ' .. tostring(battery_percentage) .. '%',
        command = '/usr/local/bin/OSDBatteryTester batteryLevelCheck -m ' .. tostring(battery_percentage)
    }
end
