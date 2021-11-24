local WaitForAdapterDetails = require 'classes.WaitForAdapterDetails'
local adapters = require 'adapters'

-- "AdapterDetails" = {"Source"=0,"SharedSource"=0,"AdapterID"=2,"FamilyCode"=18446744073172697091,"Watts"=5,"Current"=1000,"PMUConfiguration"=1000,"Voltage"=5000,"Description"="usb brick"}
return function()
    return WaitForAdapterDetails('B1', adapters.B1)
end
