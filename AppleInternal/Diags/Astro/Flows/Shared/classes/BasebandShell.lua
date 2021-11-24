local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local iosdebug = require 'iosdebug'

local BasebandShell = objects.Class(DebugShell)

function BasebandShell:debug_actions()
    iosdebug.baseband.save_baseband_debug_results(self, self:debug_log_dir(), true)
end

function BasebandShell:debug_result(result)
    self:debug_actions()
    DebugShell.debug_result(self, result)
end

function BasebandShell:debug_timeout(proc)
    DebugShell.debug_timeout(self, proc)
    self:debug_actions()
end

return BasebandShell
