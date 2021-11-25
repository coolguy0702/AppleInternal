local objects = require 'objects'
local PowerTestShell = require 'classes.PowerTestShell'
local verify = require 'verify'

local BatteryThermistorDelta = objects.Class(PowerTestShell)

-- Function expects limit and sensor name
-- BatteryTest can take -s with sensor id. Default sensor id is defined by OSDSensorModel
function BatteryThermistorDelta:init(args)
    local limit = 5 -- default value
    local sensor_name = nil

    local name = 'Battery Thermistor Delta'
    local description = 'Battery Thermistor Delta'
    local results_name = 'BatteryThermistorDelta'
    local pdca_path = '/private/var/logs/BurnIn/PDCA/_pdca_battery'
    local command = '/usr/local/bin/BatteryTest -t 65'

    if args ~= nil then
        verify.number(args.limit, "Limit for BatteryThermistorDelta test should be a number")
        limit = args.limit
        if args.sensor_name ~= nil then
            verify.string(args.sensor_name, "sensorId for BatteryThermistorDelta test should be a string")
            sensor_name = args.sensor_name
        end
    end

    if sensor_name then
        name = name .. ' Sensor ' .. sensor_name
        description = description .. ' Sensor ' .. sensor_name
        results_name = results_name .. 'Sensor' .. sensor_name
        pdca_path = pdca_path .. '_sensor' .. sensor_name
        command = command .. ' -s ' .. sensor_name
    end

    name = name .. ' Limit ' .. limit
    description = description .. ' Limit ' .. limit
    results_name = results_name .. 'Limit' .. limit
    pdca_path = pdca_path .. '_limit' .. limit .. '.plist'
    command = command .. ' -l ' .. limit .. ' -r ' .. pdca_path

    PowerTestShell.init(self, {
        name = name,
        description = description,
        results_name = results_name,
        command = command,
        pdca_plist_paths = {pdca_path}
    })
end

return BatteryThermistorDelta
