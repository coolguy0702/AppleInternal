local DebugShell = require 'flowextensions.DebugShell'

-- Check if Baseband is still running
return function()
    return DebugShell {
        name = "Check baseband alive",
        command = "/usr/local/bin/BasebandCrashCheck -s 8",
        timeout = 300, -- TODO: <rdar://problem/36007943> Port BasebandCrashCheck to FactoryToolbox's OSDBaseband
    }
end
