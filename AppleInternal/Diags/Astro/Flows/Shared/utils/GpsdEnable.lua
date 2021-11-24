local Step = require 'flow.Step'
local launchd = require 'launchd'

local GPSD_PLIST = '/System/Library/LaunchDaemons/com.apple.gpsd.plist'

return function()
    return Step {
        name = 'gpsd loading enable',
        description = 'gpsd loading enable',
        main = function()
            launchd.load(GPSD_PLIST, true)
        end
    }

end
