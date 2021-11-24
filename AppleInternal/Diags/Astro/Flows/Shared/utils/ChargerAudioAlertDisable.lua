local ioaccessory = require 'ioaccessory'
local Step = require 'flow.Step'

return function()
    return Step('Disable charger audio notifications', function ()
        ioaccessory.__disable_audio_if_charger_disconnected()
    end)
end
