-- CoreCapture Node
local objects = require 'objects'
local Node = require 'flow.classes.Node'
local astro = require 'astro'
local fs = require 'filesystem'
local corecapture = require 'corecapture'
local iosdebug = require 'iosdebug'

local CoreCapture = objects.Class(Node)

function CoreCapture:init(label)
    label = label or 'Unnamed'

    local representation = astro.viz.Step {
        metadata = {
            name = "CoreCapture - " ..  label,
            description = "CoreCapture - " ..  label,
            results_name = "CoreCapture-" ..  label,
        }
    }
    Node.init(self, representation)

    self.label = label
end

function CoreCapture:run()
    -- In the event that BT crashed, we will want the BT packet logs from
    -- /private/var/logs/MobileLibraryLogs/Bluetooth
    -- We have to check this first because CoreCapture will remove the BT crash, if it exsists
    if corecapture.did_bluetooth_crash() then
        local destination_path = self:get_log_dir('CoreCapture')
        fs.mkdirs(destination_path)

        iosdebug.bluetooth.save_bt_packet_logs(self, destination_path)
    end

    if corecapture.any_crash() then
        local destination_path = self:get_log_dir('CoreCapture')
        fs.mkdirs(destination_path)
        corecapture.cleanup({'.'}, destination_path)

        self:save_pdca_records {
            {
                name = 'Detected CoreCapture - ' .. self.label,
                pass = false
            }
        }
    end


end

return CoreCapture
