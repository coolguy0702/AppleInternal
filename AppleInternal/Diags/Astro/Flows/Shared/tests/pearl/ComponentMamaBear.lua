-- TODO: Test Documentation
-- Component Mamabear: 0x14 indicates that Mamabear is armed, 0x1c indicates bricked, and 0x11 indicates unarmed.
local ISPFWLogShell = require 'flowextensions.ISPFWLogShell'

return function()
    return ISPFWLogShell {
        name = 'Component MamaBear',
        description = 'Component MamaBear - read MB status and expect 0x14 (Armed, not enabled)',
        command = '/usr/local/bin/OSDPearlTester MamaBearStatus --expect 0x14',
    }
end
