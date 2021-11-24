-- <rdar://problem/48677676> J4xx Bring Up (Astro) - sleep/reboot tests
-- <rdar://problem/40728712> J3xx Potomac FLT_OVER_TEMP Test

local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = "Potomac Die Temp Fault",
        decription = "Check Potomac FLT_OVER_TEMP Register",
        results_name = "PotomacDieTempFault",
        command = 'smcif -i2cWriteRead 0x00 0xEA 0x1 0x2 0x13 0x00 | grep "SMBR = 0x00"'
    }

end
