local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local spu_version = require 'versions.spu'
local iosdebug = require "iosdebug"

local Accelerometer = objects.Class(DebugShell)

function Accelerometer:init()
    DebugShell.init(self, {
        name = "Accelerometer",
        command = '/usr/local/bin/AccelerometerTest',
        timeout = 30,
    })
end

function Accelerometer:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    self:save_software_attributes {
        spu_firmware_version = spu_version()
    }
end

function Accelerometer:debug_result(result)
    self:debug_steps()
    DebugShell.debug_result(self, result)
end

function Accelerometer:debug_timeout(proc)
    self:debug_steps()
    DebugShell.debug_timeout(self, proc)
end

function Accelerometer:debug_steps()
    iosdebug.spu.save_spu_debug_results(self, self:debug_log_dir())
end

return Accelerometer
