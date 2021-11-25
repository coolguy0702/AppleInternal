local WaitForAdapterDetails = require 'classes.WaitForAdapterDetails'
local adapters = require 'adapters'

-- "AdapterDetails" = {"SerialString"="C3D8343A09VGKVP3S","Watts"=18,"Amperage"=2000,"Description"="pd charger","PMUConfiguration"=2000,
--                     "Model"="0x1675","Name"="18W USB-C Power Adapter","FamilyCode"=18446744073172697095,"FwVersion"="01030061",
--                     "AdapterVoltage"=9000,"SharedSource"=0,"AdapterID"=0,"UsbHvcHvcIndex"=1,
--                     "UsbHvcMenu"=({"Index"=0,"MaxCurrent"=3000,"MaxVoltage"=5000},{"Index"=1,"MaxCurrent"=2000,"MaxVoltage"=9000}),
--                     "SourceID"=0,"HwVersion"="DVT0400MA1W1","Manufacturer"="Apple Inc."} IOAccessoryManager primary port 512

return function()
    return WaitForAdapterDetails('B400_B1', adapters.B400, adapters.B1)
end
