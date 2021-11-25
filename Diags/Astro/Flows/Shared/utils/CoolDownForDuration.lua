local verify = require 'verify'
local Shell = require 'flow.Shell'
local Sequence = require "flow.Sequence"

return function(seconds)
    -- This function will do a best effort to cool by turning off the display and charger
    local timeout = 30
    verify.number(seconds, 'The "seconds" parameter must be a number');

    if seconds < 0 then
        error('Seconds arg was ' .. seconds .. ' seconds but must be greater than 0');
    end

    return Sequence {
        name = "Cool down for duration",
        Shell {
            name = 'Disabling charging',
            command = '/usr/local/bin/setbatt drain &',
            timeout = timeout,
        },
        Shell {
            name = 'Turn off display',
            command = '/usr/local/bin/powerswitch lcd off',
            timeout = timeout,
        },
        Shell {
            name = 'Wait for ' .. seconds .. ' secs',
            command = '/bin/sleep ' .. seconds,
            timeout = seconds + timeout,
        },
        Shell {
            name = 'Killall setbatt charging',
            command = '/usr/bin/killall -9 setbatt',
            timeout = timeout,
        },
        Shell {
            name = 'Turn on display',
            command = '/usr/local/bin/powerswitch lcd on',
            timeout = timeout,
        },
        Shell {
            name = 'Enable charging',
            command = '/usr/local/bin/setbatt on',
            timeout = timeout,
        },
    }
end
