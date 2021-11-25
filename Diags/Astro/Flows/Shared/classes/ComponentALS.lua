local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local spu_version = require 'versions.spu'
local iosdebug = require "iosdebug"

local ComponentALS = objects.Class(DebugShell)

function ComponentALS:init()
    DebugShell.init(self, {
        name = 'Component ALS',
        command = '/usr/local/bin/Component -check als',
        timeout = 30,
    })
end

function ComponentALS:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    self:save_software_attributes {
        spu_firmware_version = spu_version()
    }
end

function ComponentALS:debug_result(result)
    DebugShell.debug_result(self, result)
    self:debug_steps()
end

function ComponentALS:debug_timeout(proc)
    DebugShell.debug_timeout(self, proc)
    self:debug_steps()
end

function ComponentALS:debug_steps()
    iosdebug.als.save_als_debug_results(self, self:debug_log_dir())
end

return ComponentALS
