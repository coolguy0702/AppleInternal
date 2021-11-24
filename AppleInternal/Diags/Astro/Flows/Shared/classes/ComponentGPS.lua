local objects = require 'objects'
local verify = require "verify"
local DebugShell = require 'flowextensions.DebugShell'
local launchd = require 'launchd'
local gpsdPlist = '/System/Library/LaunchDaemons/com.apple.gpsd.plist'
local iosdebug = require 'iosdebug'

local ComponentGPS = objects.Class(DebugShell)

-- The function expects args with name, results_name, should_unload_gpsd, options
function ComponentGPS:init(args)
    local command = '/usr/local/bin/OSDComponent gps'

    verify.table(args, "args should be a table")
    verify.string(args.name, "name should be a string")
    verify.string(args.results_name, "results_name should be a string")

    if args.should_unload_gpsd ~= nil then
        verify.boolean(args.should_unload_gpsd, "should_unload_gpsd should be boolean")
    end

    if args.options ~= nil then
        verify.table(args.options, "options should be a table")
        for _, value in pairs(args.options) do
            command = command .. ' --' .. value
        end
    end

    DebugShell.init(self, {
        name = args.name,
        results_name = args.results_name,
        command = command,
        timeout = 30,
    })

    self.should_unload_gpsd = args.should_unload_gpsd
end

function ComponentGPS:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    -- By default always unload unless should_unload_gpsd is false
    if self.should_unload_gpsd ~= false then
        print('Unloading ' .. gpsdPlist)
        launchd.unload(gpsdPlist)
    end
end

function ComponentGPS:teardown()
    DebugShell.teardown(self) -- Have DebugShell do teardown first

    if self.should_unload_gpsd ~= false then
        print('Loading ' .. gpsdPlist)
        launchd.load(gpsdPlist)
    end
end

function ComponentGPS:debug_result(result)
    self:debug_steps()
    DebugShell.debug_result(self, result)
end

function ComponentGPS:debug_timeout(proc)
    self:debug_steps()
    DebugShell.debug_timeout(self, proc)
end

function ComponentGPS:debug_steps()
    iosdebug.gps.save_gps_debug_results(self, self:debug_log_dir())
end

return ComponentGPS
