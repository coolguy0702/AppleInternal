local classes = require 'classes'
local PearlTherm = classes.PearlTherm

return function()
    return PearlTherm {
        -- (30/30*10)+(300/30*7)+(600/30*2) = 120s
        duration = 120,
        counts_and_intervals = "--interval 30 --count 10 --interval 300 --count 7 --interval 600 --count 2",
        bane = false,
    }
end
