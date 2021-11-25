local verify = require 'verify'
local Shell = require 'flow.Shell'

return function(nits)
    -- This function will set the brightness to the desired nits
    -- nits must be a value between [0, 750]
    local timeout = 30
    verify.number(nits, 'The "nits" parameter must be a number');

    if nits < 0 then
        error('Value was ' .. nits .. ' but should be greater than 0 when setting nits');
    end

    return Shell {
            name = 'Setting brightness to ' .. nits .. ' nits',
            command = '/usr/local/bin/SetBrightness -set BrightnessNits ' .. nits,
            timeout = timeout,
        }
end
