local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local spu_version = require 'versions.spu'
local iosdebug = require "iosdebug"

local ComponentSPUSensors = objects.Class(DebugShell)

function ComponentSPUSensors:init()
    DebugShell.init(self, {
        name = "ComponentSPUSensors",
        command = '/usr/local/bin/Component -check spusensors',
        timeout = 30,
    })
end

function ComponentSPUSensors:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    self:save_software_attributes {
        spu_firmware_version = spu_version()
    }
end

function ComponentSPUSensors:debug_result(result)
    self:debug_steps()
    DebugShell.debug_result(self, result)
end

function ComponentSPUSensors:debug_timeout(proc)
    self:debug_steps()
    DebugShell.debug_timeout(self, proc)
end

function ComponentSPUSensors:debug_steps()
    iosdebug.spu.save_spu_debug_results(self, self:debug_log_dir())
end

return ComponentSPUSensors
