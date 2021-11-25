local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local fs = require 'filesystem'

local PRTTShell = objects.Class(DebugShell)

function PRTTShell:_save_debug()
    local debug_path = self:debug_log_dir()
    fs.mkdirs(debug_path)

    local coremotion_path = fs.path.join(debug_path, 'CoreMotion')
    fs.copy('/var/logs/BurnIn/CoreMotion', coremotion_path)
    self:save_file_result {
        path = coremotion_path,
        metadata = {
            description = 'CoreMotion debug path'
        }
    }

    local prtt_path = fs.path.join(debug_path, 'prtt.db')
    fs.copy('/private/var/logs/BurnIn/prtt.db', prtt_path)
    self:save_file_result {
        path = prtt_path,
        metadata = {
            description = 'PRTT database'
        }
    }
end

function PRTTShell:debug_result(result)
    self:_save_debug()
    DebugShell.debug_result(self, result)
end

function PRTTShell:debug_timeout(proc)
    DebugShell.debug_timeout(self, proc)
    self:_save_debug()
end

return PRTTShell
