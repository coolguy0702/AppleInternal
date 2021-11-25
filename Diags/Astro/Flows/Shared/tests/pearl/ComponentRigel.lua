-- TODO: Test Documentation
-- Component Rigel: 0x24 indicates that the main FSM register of 0x07 is in OSDRigelMainStateStandbyWaitOff, which is the nominal mode for this ping
local ISPFWLogShell = require 'flowextensions.ISPFWLogShell'

return function()
    return ISPFWLogShell {
        name = 'Component Rigel',
        description = 'Component Rigel - read Rigel status and expect 0x24',
        command = '/usr/local/bin/OSDPearlTester RigelStatus --expect 0x24',
    }
end
