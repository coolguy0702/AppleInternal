local Step = require 'flow.Step'
local launchd = require 'launchd'

local GPSD_PLIST = '/System/Library/LaunchDaemons/com.apple.gpsd.plist'

return function()
    return Step {
        name = 'gpsd loading disable',
        description = 'gpsd loading disable',
        main = function()
            launchd.unload(GPSD_PLIST, true)
        end
    }

end
