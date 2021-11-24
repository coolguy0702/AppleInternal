local WaitForAdapterDetails = require 'classes.WaitForAdapterDetails'
local adapters = require 'adapters'

return function()
    return WaitForAdapterDetails('B400_B488_B45', adapters.B400, adapters.B488, adapters.B45)
end
