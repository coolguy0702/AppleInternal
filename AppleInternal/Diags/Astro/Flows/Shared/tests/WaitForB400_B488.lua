local WaitForAdapterDetails = require 'classes.WaitForAdapterDetails'
local adapters = require 'adapters'

return function()
    return WaitForAdapterDetails('B400_B488', adapters.B400, adapters.B488)
end
