local ioaccessory = require 'ioaccessory'
local Step = require 'flow.Step'

return function()
    return Step('Enable charger audio notifications', function ()
        ioaccessory.__enable_audio_if_charger_disconnected('/AppleInternal/Applications/SwitchBoard/Ness.app/heartpiece.caf', 0.3)
    end)
end
