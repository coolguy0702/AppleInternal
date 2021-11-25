local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local iosdebug = require 'iosdebug'

local GrapeTestShell = objects.Class(DebugShell)

function GrapeTestShell:debug_result(result)
    iosdebug.grape.save_grape_debug_results(self, self:debug_log_dir())
    DebugShell.debug_result(self, result)
end

function GrapeTestShell:debug_timeout(proc)
    DebugShell.debug_timeout(self, proc)
    iosdebug.grape.save_grape_debug_results(self, self:debug_log_dir())
end

return GrapeTestShell
