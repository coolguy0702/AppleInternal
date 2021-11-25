local PowerTestShell = require 'classes.PowerTestShell'
local verify = require 'verify'

-- Example args:
-- {
--      level = 50,
--      timeout = 3600,
--      interval = 60,
--      label = 'ChargeTo50'
-- }
return function(args)
--     -c, --desiredLevel=arg : Desired battery state of charge to wait for
--     -t, --timeout=arg    : Maximum time to wait
--     -i, --interval=arg   : Interval between printing charge stats
--     -p, --pdcaPath=arg   : PDCA plist path
--     -l, --label=arg      : PDCA label

    local pdca_path = '$ASTRO_WORKING_DIRECTORY/logs/battery.plist'
    local command = '/usr/local/bin/OSDBatteryTester SMCWaitForCharge --pdcaPath=' .. pdca_path
    local battery_level = 50
    local timeout = 3600 -- default one hour

    if args ~= nil then
        verify.table(args, 'args must be a table')

        if args.timeout ~= nil then
            verify.number(args.timeout, 'timeout must be a number')
            timeout = args.timeout
        end

        if args.battery_level ~= nil then
            verify.number(args.battery_level, 'battery_level must be a number')
            battery_level = args.battery_level
        end

        if args.interval ~= nil then
            verify.number(args.interval, 'interval must be a number')
            command = command .. ' --interval=' .. args.interval
        end

        if args.label ~= nil then
            verify.string(args.label, 'label must be a string')
            command = command .. ' --label=' .. args.label
        end

    end

    command = command .. ' --desiredLevel=' .. battery_level .. ' --timeout=' .. timeout

    return PowerTestShell {
        name = 'Charge battery to ' .. battery_level .. '%',
        command = command,
        timeout = timeout + 60, -- Give another minute in addition to the timeout
        pdca_plist_paths = {pdca_path}
    }
end
