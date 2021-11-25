local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local iosdebug = require 'iosdebug'

local MesaTestShell = objects.Class(DebugShell)

function MesaTestShell:debug_result(result)
    iosdebug.mesa.save_mesa_debug_results(self, self:debug_log_dir())
    DebugShell.debug_result(self, result)
end

function MesaTestShell:debug_timeout(proc)
    iosdebug.mesa.save_mesa_debug_results(self, self:debug_log_dir())
    DebugShell.debug_timeout(self, proc)
end

return MesaTestShell
