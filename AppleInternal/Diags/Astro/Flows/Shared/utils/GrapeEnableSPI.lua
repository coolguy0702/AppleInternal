local GrapeTestShell = require 'classes.GrapeTestShell'

return function()
    return GrapeTestShell {
        name = 'Grape Enable SPI Communication',
        command = '/usr/local/bin/mtreport set 0xC8 0x1E'
    }
end
