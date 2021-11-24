local Sequence = require "flow.Sequence"
local Shell = require 'flow.Shell'

return function()
    return  Sequence {
        name = 'Additional WiFi logging',
        Shell {
            name = 'Enable WiFi logging',
            command = '/usr/local/bin/mobilewifitool -- log --enable=1'
        },
        Shell {
            name = 'WiFi logging to file',
            command = '/usr/local/bin/mobilewifitool -- log --fileEnable=1'
        },
    }
end
