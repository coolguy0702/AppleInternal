local Sequence = require 'flow.Sequence'
local DebugShell = require 'flowextensions.DebugShell'
local ComponentWifi = require 'tests.ComponentWifi'

return function()
    return Sequence {
        on_enter = {
            ComponentWifi()
        },

        DebugShell {
            name = 'Wake On WiFi',
            command = '/usr/local/bin/OSDWakeOn --test=wifi --opRetry=5 --chgRetry=5 --battery=30 --allRetry=YES --overrideWakeReason="wifibt&wlan"',
            timeout = 100
        },
    }
end
