local Shell = require 'flow.Shell'

return function()
    return Shell {
            name = 'Enable sysmptomsd autobugcapture',
            command = 'login -f mobile defaults delete com.apple.symptomsd-diag disable_autobugcapture',
        }
end
