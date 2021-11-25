-- <rdar://problem/48603162> J4xx Bring Up (Astro) - Venus
-- Stockholm is Secure Element + Antenna; Rotterdam and Venus are just the SE.
-- J4xx program has Venus but we are using tools from stockholm/rotterdam to test it

local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local stockholm_version = require 'versions.stockholm'
local iosdebug = require "iosdebug"

local ComponentVenus = objects.Class(DebugShell)

function ComponentVenus:init()
    DebugShell.init(self, {
        name = "Component Venus",
        results_name = "ComponentVenus",
        command = '/usr/local/bin/Component -check rotterdam',
        timeout = 60,
    })
end

function ComponentVenus:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    self:save_software_attributes {
        stockholm_firmware_version = stockholm_version()
    }
end

function ComponentVenus:debug_result(result)
    self:debug_steps()
    DebugShell.debug_result(self, result)
end

function ComponentVenus:debug_timeout(proc)
    self:debug_steps()
    DebugShell.debug_timeout(self, proc)
end

function ComponentVenus:debug_steps()
    iosdebug.stockholm.save_stockholm_debug_results(self, self:debug_log_dir())
end

return ComponentVenus
