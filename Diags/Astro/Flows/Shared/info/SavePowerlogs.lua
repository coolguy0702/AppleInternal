local Step = require 'flow.Step'
local iosdebug = require 'iosdebug'

return function()
    return Step {
        name = 'Save Powerlogs',
        description = 'Save Powerlogs',
        main = function(self)
            iosdebug.power.save_powerlog(self, self:get_log_dir('PowerLogs'))
        end
    }
end
