local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local spu_version = require 'versions.spu'
local iosdebug = require "iosdebug"

local ComponentPhosphorous = objects.Class(DebugShell)

function ComponentPhosphorous:init()
    DebugShell.init(self, {
        name = 'Component Pressure',
        command = '/usr/local/bin/Component -check phosphorous',
        timeout = 30
    })
end

function ComponentPhosphorous:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    self:save_software_attributes {
        spu_firmware_version = spu_version()
    }
end

function ComponentPhosphorous:debug_result(result)
    self:debug_steps()
    DebugShell.debug_result(self, result)
end

function ComponentPhosphorous:debug_timeout(proc)
    self:debug_steps()
    DebugShell.debug_timeout(self, proc)
end

function ComponentPhosphorous:debug_steps()
    iosdebug.spu.save_spu_debug_results(self, self:debug_log_dir())
end

return ComponentPhosphorous
