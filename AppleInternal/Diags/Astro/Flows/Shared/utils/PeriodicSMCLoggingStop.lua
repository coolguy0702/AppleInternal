-- <rdar://problem/48929218>

local Shell = require 'flow.Shell'

return function()
    return Shell {
        name = 'Stop Periodic SMC Key Logging',
        command = 'if pgrep -x smcif; then /usr/bin/killall -9 smcif; fi',
        timeout = 30,
    }
end
