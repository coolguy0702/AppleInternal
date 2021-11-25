local FactoryStation = require 'manufacturing.FactoryStation'
local objects = require 'objects'
local strobe = require 'strobe'
local verify = require 'verify'

local PhoneFactoryStation = objects.Class(FactoryStation)

function PhoneFactoryStation:init(info)
    FactoryStation.init(self, info)

    if info.strobe_config then
        verify.table(info.strobe_config, 'strobe must be a table')

        verify.number(info.strobe_config.level, 'strobe.level should be a number')
        verify.number(info.strobe_config.on_time, 'strobe.on_time should be a number')
        verify.number(info.strobe_config.interval, 'strobe.interval should be a number')

        self.strobe_config = info.strobe_config
    end

    -- Don't allow for use of the setup_next_station_on_pass boolean when there are next_boot_args.on_pass
    -- Phones and Pads should rely entirely on PRSq for PASS boot-arg support
    if info.setup_next_station_on_pass ~= nil
    and info.next_boot_args ~= nil
    and info.next_boot_args.on_pass ~= nil
    and #info.next_boot_args.on_pass > 0 then
        if info.setup_next_station_on_pass == true then
            error("PhoneFactoryStation does not support next_boot_args.on_pass!")
        end
    end
end

function PhoneFactoryStation:run()
    self:call_and_report_error(function () FactoryStation.run(self) end)

    if self.strobe_config then
        if strobe.has_strobe() then
            print('Device has strobe. Running strobe settings - level: ' .. self.strobe_config.level .. ', on time: ' .. self.strobe_config.on_time .. ', interval: ' .. self.strobe_config.interval)
            strobe.start(self.strobe_config.level, self.strobe_config.on_time, self.strobe_config.interval)
        else
            print('Device does not have strobe, so cannot strobe_upon_completion')
        end
    end
end

return PhoneFactoryStation
-- TODO add charger unplugged detection
