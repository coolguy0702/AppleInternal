local Shell = require 'flow.Shell'
local Reboot = require 'flow.Reboot'
local Sequence = require 'flow.Sequence'
local flowconfig = require 'flowconfig'
local CoreCaptureDeleteCores = require 'utils.CoreCaptureDeleteCores'

return function()
    return Sequence {
        name = 'CoreCapture log cleanup',
        description = 'CoreCapture log cleanup',
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        Shell {
            name = 'Disable sysmptomsd autobugcapture',
            command = 'login -f mobile defaults write com.apple.symptomsd-diag disable_autobugcapture -bool YES',
        },
        Reboot(),
        CoreCaptureDeleteCores(),
    }
end
