local WaitForAdapterDetails = require 'classes.WaitForAdapterDetails'
local adapters = require 'adapters'

-- "AdapterDetails" = {"SerialString"="C4H7482010WH80MA5","Watts"=30,"Amperage"=2000,
-- "Model"="0x1674","PMUConfiguration"=2935,"Name"="30W USB-C Power Adapter",
-- "FamilyCode"=18446744073172697098,"FwVersion"="01020063",
-- "AdapterVoltage"=15000,
-- "UsbHvcMenu"=(
-- {"Index"=0,"MaxCurrent"=3000,"MaxVoltage"=5000},
-- {"Index"=1,"MaxCurrent"=3000,"MaxVoltage"=9000},
-- {"Index"=2,"MaxCurrent"=2000,"MaxVoltage"=15000},
-- {"Index"=3,"MaxCurrent"=1500,"MaxVoltage"=20000}),
-- "AdapterID"=18446744073709551360,"UsbHvcHvcIndex"=0,"Manufacturer"="Apple Inc."}

return function()
    return WaitForAdapterDetails('B488', adapters.B488)
end
