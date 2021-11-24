local Sequence = require 'flow.Sequence'
local DebugShell = require 'flowextensions.DebugShell'
local ComponentBluetooth = require 'tests.ComponentBluetooth'

return function()
    return Sequence {
        on_enter = {
            ComponentBluetooth()
        },

        DebugShell {
            name = 'Wake On Bluetooth',
            command = '/usr/local/bin/OSDWakeOn --test=bluetooth --opRetry=5 --chgRetry=5 --battery=30 --allRetry=YES --overrideWakeReason="wifibt&bluetooth-pcie"',
            timeout = 100
        },
    }
end
