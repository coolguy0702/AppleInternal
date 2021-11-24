-- Continually sample compass

local DebugShell = require 'flowextensions.DebugShell'
local verify = require 'verify'

return function(interval)
    if interval == nil then
        interval = 0.01
    else
        verify.number(interval, 'Interval must be a number')
    end

    return DebugShell {
        name = 'Background Compass Sampling',
        results_name = 'BackgroundCompass',
        command = '/usr/local/bin/compassTester -interval ' .. interval .. ' > /dev/null &',
    }
end
