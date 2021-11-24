-- TODO: Test Documentation
-- Component Yogi: This tool will ping the Yogi IC through ISP->AOP->I2C->Yogi and check its status register. We expect no faults.
local ISPFWLogShell = require 'flowextensions.ISPFWLogShell'

return function()
    return ISPFWLogShell {
        name = 'Component Yogi',
        description = 'Component Yogi - read Yogi status and expect 0x00',
        command = '/usr/local/bin/OSDPearlTester YogiStatus --expect 0x00',
    }
end
