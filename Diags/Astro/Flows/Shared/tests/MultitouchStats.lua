local If = require 'flow.If'
local Condition = require 'flow.classes.Condition'
local DebugShell = require 'flowextensions.DebugShell'

local flowconfig = require 'flowconfig'

return function()
    local reduced_pdca = flowconfig.getglobal('reduced_pdca', false)

    return If(Condition('Run MultitouchStats', function() return reduced_pdca == false end)) {
        DebugShell {
            name = 'Multitouch Stats',
            command = '/usr/local/bin/HWStatsCollector -softwareName MultitouchCheck -pdcaOutputPath /private/var/logs/BurnIn/PDCA/_pdca_MultitouchCheck.plist -label Component',
            pdca_plist_paths = {"/private/var/logs/BurnIn/PDCA/_pdca_MultitouchCheck.plist"}
        }
    }
end
