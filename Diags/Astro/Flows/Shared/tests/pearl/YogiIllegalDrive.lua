local ISPFWLogShell = require "flowextensions.ISPFWLogShell"
local Sequence = require "flow.Sequence"
local Step = require 'flow.Step'
local Condition = require "flow.classes.Condition"
local If = require "flow.If"
local Reboot = require "flow.Reboot"
local processutils = require "processutils"
local flowconfig = require 'flowconfig'
local device = require 'device'

local yogilatched = function()
    local status = processutils.launch_shell("OSDPearlTester YogiStatus --expect 0x00")
    local _, result = status:wait_until_exit_or_timeout(nil)

    if result.code == 0 and result.reason == "exit" then
        print("Yogi does not appear to have latched")
        return false
    end

    print("Yogi appears to have latched")
    return true
end

local YogiLatchCondition = Condition(yogilatched, "Yogi did latch")



return function()
    return Sequence {
        name = "Rosaline/Vader decision sequence",
        continue_on_fail = true, -- Must hard-code to true to get if-else behavior

        If(Condition("Rosaline", function() return not device.has_vader() end)) {
            Sequence {
                description = "Yogi Illegal Drives",
                continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

                Sequence {
                    description = "Yogi Illegal Drive - Fault C",
                    continue_on_fail = true,

                    ISPFWLogShell {
                        name = "Yogi Fault C",
                        results_name = "YogiFaultC",
                        command = "OSDPearlTester YogiIllegalDrive --mode fault-c --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_yogi_fault_c.plist",
                        pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_yogi_fault_c.plist"}
                    },

                    If(YogiLatchCondition) {
                        Reboot(),
                    },
                },

                Sequence {
                    description = "Yogi Illegal Drive - Fault D",
                    continue_on_fail = true,

                    ISPFWLogShell {
                        name = "Yogi Fault D",
                        results_name = "YogiFaultD",
                        command = "OSDPearlTester YogiIllegalDrive --mode fault-d --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_yogi_fault_d.plist",
                        pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_yogi_fault_d.plist"}
                    },

                    If(YogiLatchCondition) {
                        Reboot(),
                    },
                },

                Sequence {
                    description = "Yogi Illegal Drive - Fault E",
                    continue_on_fail = true,

                    ISPFWLogShell {
                        name = "Yogi Fault E",
                        results_name = "YogiFaultE",
                        command = "OSDPearlTester YogiIllegalDrive --mode fault-e --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_yogi_fault_e.plist",
                        pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_yogi_fault_e.plist"}
                    },

                    If(YogiLatchCondition) {
                        Reboot(),
                    },
                }
            }
        },

        If(Condition("Vader", function() return device.has_vader() end)) {
            Step(
                "Fail Vader",
                function(self)
                    self:save_passfail_result {
                        name = "HasVader",
                        pass = false,
                        message = "Device has Vader",
                    }
                end
            )
        }
    }
end
