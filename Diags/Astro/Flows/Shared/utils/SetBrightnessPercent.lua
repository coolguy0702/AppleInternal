local verify = require 'verify'
local Shell = require 'flow.Shell'

return function(percent)
    -- This function will set the brightness to the desired percent
    -- percent must be a value between [0, 100]
    local timeout = 30
    verify.number(percent, 'The "percent" parameter must be a number');

    if percent < 0 or percent > 100 then
        error('Value was ' .. percent .. ' but should be [0, 100] when setting percent')
    end

    return Shell {
            name = 'Setting brightness to ' .. percent .. ' percent',
            command = '/usr/local/bin/BacklightdTester -set DisplayBrightness ' .. percent / 100,
            timeout = timeout,
        }
end
