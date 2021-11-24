local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local iosdebug = require 'iosdebug'

local PowerTestShell = objects.Class(DebugShell)

function PowerTestShell:debug_actions()
    iosdebug.power.save_power_debug_results(self, self:debug_log_dir())
    iosdebug.power.save_powerlog(self, self:debug_log_dir())
end

function PowerTestShell:debug_result(result)
    self:debug_actions()
    DebugShell.debug_result(self, result)
end

function PowerTestShell:debug_timeout(proc)
    DebugShell.debug_timeout(self, proc)
    self:debug_actions()
end

return PowerTestShell
