local PowerTestShell = require 'classes.PowerTestShell'
local verify = require 'verify'

return function(battery_percentage, timeout)
    -- Default so we can run from the CLI
    if not battery_percentage then battery_percentage = 10 end -- 10% default
    if not timeout then timeout = 3600 end -- One hour timeout default
    verify.number(battery_percentage, 'Battery percentage must be a number')
    verify.number(timeout, 'Timeout must be a number')
    local pdca_path = '$ASTRO_WORKING_DIRECTORY/logs/battery.plist'

    return PowerTestShell {
        name = 'Charge battery to ' .. battery_percentage .. '%',
        command = '/usr/local/bin/BatteryTest -g ' .. battery_percentage .. ' -r "' .. pdca_path .. '"',
        timeout = timeout,
        pdca_plist_paths = {pdca_path}
    }
end
