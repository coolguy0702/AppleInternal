local Sequence = require 'flow.Sequence'
local Shell = require 'flow.Shell'
local flowconfig = require 'flowconfig'

return function()
    return Sequence {
        name = 'Baseband Log Teardown',
        description = 'Unset factory baseband trace',
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        Shell {
            name = 'Disable BB Core Dump Logs',
            command = '/usr/local/bin/abmtool coredump enabled false',
        },
        Shell {
            name = "Disable BB background trace mode",
            command = '/usr/local/bin/abmtool trace set basebandtrace backgroundmode 0'
        },
    }
end
