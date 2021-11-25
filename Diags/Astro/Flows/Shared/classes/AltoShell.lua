local DebugShell = require "flowextensions.DebugShell"
local Exception = require "exceptions.Exception"
local processutils = require "processutils"
local fs = require "filesystem"
local altomobile_version = require 'versions.altomobile'

-- sublcass DebugShell so we can move files around and debug cleanly
local objects = require "objects"
local Class = objects.Class
local AltoShell = Class(DebugShell)

function AltoShell:alto_log_dir()
    return self:get_log_dir("AltoMobile")
end

function AltoShell:debug_log_dir()
    return self:get_log_dir("Debug/AltoMobile")
end

function AltoShell:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    self:save_software_attributes {
        altomobile_version = altomobile_version()
    }
end

function AltoShell:process_result(result)
    -- First call super so the PDCA is imported correctly. This will also call debug if it failed
    DebugShell.process_result(self, result)
    -- TODO: We probably want to do some debug if we import failing PDCA records as well?

    fs.mkdirs(self:alto_log_dir())

    -- Now move the files to the log directory: /var/logs/Astro/flow.astro/logs/AltoMobile/datestamp/Alto
    local mv = processutils.launch_exec("/bin/mv", {"/private/var/logs/BurnIn/Alto", self:alto_log_dir()})
    local mv_complete, mv_result = mv:wait_until_exit_or_timeout(10)

    -- If astro didn't exit successfully, this is best effort
    if result.code == 0 and (not mv_complete or mv_result.code ~= 0) then
        error(Exception("Failed to move Alto logs!"))
    end
end

return AltoShell
