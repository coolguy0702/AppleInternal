-- <rdar://problem/48677676> J4xx Bring Up (Astro) - sleep/reboot tests

local DebugShell = require 'flowextensions.DebugShell'

return function()
    return DebugShell {
        name = "EDP Training Check",
        results_name = "EDPTrainingCheck",
        command = "/usr/local/bin/LCDTest -d"
    }

end
