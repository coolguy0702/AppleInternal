local Shell = require 'flow.Shell'

return function()
    return Shell {
        name = 'Disable WiFi logging',
        command = '/usr/local/bin/mobilewifitool -- log --enable=0'
    }
end
