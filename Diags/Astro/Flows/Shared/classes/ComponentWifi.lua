-- Do a WiFi scan
local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'
local corecapture = require 'corecapture'
local wifi_version = require 'versions.wifi'
local iosdebug = require 'iosdebug'

local ComponentWifi = objects.Class(DebugShell)

function ComponentWifi:init()
    DebugShell.init(self, {
        name = 'Component WiFi',
        command = '/usr/local/bin/Component -check wifi',
        results_name = 'ComponentWiFi',
        timeout = 30,
        metadata = {
            technologies = {'wifi'}
        }
    })
end

function ComponentWifi:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    self:save_software_attributes {
        wifi_firmware_version = wifi_version()
    }
    print('Checking CoreCapture')
    local did_wifi_previously_crash = corecapture.did_wifi_crash()
    self:save_pdca_records {
        {
            name = "CoreCapture pre Component WiFi",
            pass = not did_wifi_previously_crash,
            message = "Found CoreCapture crashes"
        }
    }

    self.cleanup_path = self:debug_log_dir()
    if did_wifi_previously_crash then
        corecapture.wifi_cleanup(self.cleanup_path .. '/CoreCapture/Pretest')
    end

end

function ComponentWifi:process_timeout(proc)
    DebugShell.process_timeout(self, proc)
    iosdebug.wifi.save_wifi_debug_results(self, self.cleanup_path)
    iosdebug.timeout.save_timeout_results(self, proc, self.cleanup_path)
end

function ComponentWifi:process_result(result)
    if result.code ~= 0 then
        iosdebug.wifi.save_wifi_debug_results(self, self.cleanup_path)
    end

    DebugShell.process_result(self, result)
end

function ComponentWifi:teardown()
    DebugShell.teardown(self) -- Have DebugShell do teardown first

    print('Checking CoreCapture')
    local did_wifi_crash_after_test = corecapture.did_wifi_crash()
    self:save_pdca_records {
        {
            name = "CoreCapture post Component WiFi",
            pass = not did_wifi_crash_after_test,
            message = "Found CoreCapture crashes"
        }
    }

    if did_wifi_crash_after_test then
        corecapture.wifi_cleanup(self.cleanup_path .. '/CoreCapture/Posttest')
    end
end

return ComponentWifi
