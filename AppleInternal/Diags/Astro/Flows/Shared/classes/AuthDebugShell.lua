local objects = require 'objects'
local processutils = require 'processutils'
local fs = require 'filesystem'
local DebugShell = require 'flowextensions.DebugShell'
local verify = require "verify"

local AuthDebugShell = objects.Class(DebugShell)

function AuthDebugShell:init(args)
    verify.table(args, "args should be a table")
    verify.string(args.fdr_key, "args.fdr_key must be a string")
    self.fdr_key = args.fdr_key

    DebugShell.init(self, args)
end

function AuthDebugShell:debug_result(result)
    self:debug_steps()
    DebugShell.debug_result(self, result)
end

function AuthDebugShell:debug_timeout(proc)
    DebugShell.debug_timeout(self, proc)
    self:debug_steps()
end

function AuthDebugShell:debug_steps()
    fs.mkdirs(self:debug_log_dir())
    local payload_path = fs.path.join(self:debug_log_dir(), self.fdr_key .. "_payload.bin")
    local command = string.format(
        "/usr/local/bin/OSDToolbox FDR -k %s --AMFDRSealingMapCopy --outputPath %s",
        self.fdr_key,
        payload_path
    )

    processutils.shell(command, 30)
end

return AuthDebugShell
