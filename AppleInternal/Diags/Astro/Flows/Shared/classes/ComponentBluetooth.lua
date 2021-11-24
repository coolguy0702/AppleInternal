-- TODO: Documentation
-- Do a Bluetooth scan
local objects = require 'objects'
local Shell = require 'flow.Shell'
local corecapture = require 'corecapture'
local bt_version = require 'versions.bluetooth'
local iosdebug = require 'iosdebug'

local ComponentBluetooth = objects.Class(Shell)

function ComponentBluetooth:init()
    Shell.init(self, {
        name = 'Component Bluetooth',
        command = '/usr/local/bin/Component -check bluetooth',
        timeout = 30,
        metadata = {
            technologies = {'bluetooth'}
        }
    })
end

function ComponentBluetooth:setup()
    self:save_software_attributes {
        bluetooth_firmware_version = bt_version()
    }

    print('Checking CoreCapture')
    local did_bluetooth_previously_crash = corecapture.did_bluetooth_crash()
    self:save_pdca_records {
        {
            name = "CoreCapture pre Component Bluetooth",
            pass = not did_bluetooth_previously_crash,
            message = "Found CoreCapture crashes"
        }
    }

    self.cleanup_path = self:get_log_dir('ComponentBluetooth')
    if did_bluetooth_previously_crash then
        corecapture.bluetooth_cleanup(self.cleanup_path .. '/CoreCapture/Pretest')
        iosdebug.bluetooth.save_bt_packet_logs(self, self.cleanup_path .. '/CoreCapture/Pretest')
    end

end

function ComponentBluetooth:failure_actions()
    iosdebug.bluetooth.save_bt_core_dump(self, self.cleanup_path, "ComponentBTCoreDump")
    iosdebug.bluetooth.save_bt_packet_logs(self, self.cleanup_path)
end

function ComponentBluetooth:process_timeout(proc)
    self:failure_actions()
    Shell.process_timeout(self, proc)
    iosdebug.timeout.save_timeout_results(self, proc, self.cleanup_path)
end

function ComponentBluetooth:process_result(result)
    if result.code ~= 0 then
       self:failure_actions()
    end

    Shell.process_result(self, result)
end

function ComponentBluetooth:teardown()
    print('Checking CoreCapture')
    local did_bluetooth_crash_after_test = corecapture.did_bluetooth_crash()
    self:save_pdca_records {
        {
            name = "CoreCapture post Component Bluetooth",
            pass = not did_bluetooth_crash_after_test,
            message = "Found CoreCapture crashes"
        }
    }

    if did_bluetooth_crash_after_test then
        corecapture.bluetooth_cleanup(self.cleanup_path .. '/CoreCapture/Posttest')
        iosdebug.bluetooth.save_bt_packet_logs(self, self.cleanup_path .. '/CoreCapture/Posttest')
    end
end

return ComponentBluetooth
