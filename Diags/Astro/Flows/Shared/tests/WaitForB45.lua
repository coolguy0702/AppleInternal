local WaitForAdapterDetails = require 'classes.WaitForAdapterDetails'
local adapters = require 'adapters'

return function()
    return WaitForAdapterDetails('B45', adapters.B45)
end
