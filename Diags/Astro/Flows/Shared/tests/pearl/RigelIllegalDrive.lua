local ISPFWLogShell = require "flowextensions.ISPFWLogShell"
local Sequence = require "flow.Sequence"

return function()
    return Sequence {
        description = "Rigel Illegal Drive",
        continue_on_fail = false, -- Failures in baseline should not continue to the Illegal Drives

        ISPFWLogShell {
            name = "Rigel Baseline 30",
            results_name = "RigelBaseline30",
            command = "OSDPearlTester RigelIllegalDrive --mode baseline-30 --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_baseline_30.plist",
            timeout = 10, -- a very short test
            pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_baseline_30.plist",}
        },

        ISPFWLogShell {
            name = "Rigel Baseline 60",
            results_name = "RigelBaseline60",
            command = "OSDPearlTester RigelIllegalDrive --mode baseline-60 --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_baseline_60.plist",
            timeout = 10, -- a very short test
            pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_baseline_60.plist",}
        },

        ISPFWLogShell {
            name = "Rigel IOUT0 max pulse width",
            results_name = "RigelIOUT0PW",
            command = "OSDPearlTester RigelIllegalDrive --mode iout0-max-pw --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout0_pw.plist",
            timeout = 10, -- a very short test
            pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout0_pw.plist",}
        },

        ISPFWLogShell {
            name = "Rigel IOUT1 max pulse width",
            results_name = "RigelIOUT1PW",
            command = "OSDPearlTester RigelIllegalDrive --mode iout1-max-pw --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout1_pw.plist",
            timeout = 10, -- a very short test
            pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout1_pw.plist",}
        },

        ISPFWLogShell {
            name = "Rigel IOUT0 max duty cycle",
            results_name = "RigelIOUT0DC",
            command = "OSDPearlTester RigelIllegalDrive --mode iout0-max-dc --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout0_dc.plist",
            timeout = 10, -- a very short test
            pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout0_dc.plist",}
        },

        ISPFWLogShell {
            name = "Rigel IOUT1 max duty cycle",
            results_name = "RigelIOUT1DC",
            command = "OSDPearlTester RigelIllegalDrive --mode iout1-max-dc --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout1_dc.plist",
            timeout = 10, -- a very short test
            pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout1_dc.plist",}
        },

        ISPFWLogShell {
            name = "Rigel IOUT0 max pulse count",
            results_name = "RigelIOUT0PC",
            command = "OSDPearlTester RigelIllegalDrive --mode iout0-max-pc --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout0_pc.plist",
            timeout = 10, -- a very short test
            pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout0_pc.plist",}
        },

        ISPFWLogShell {
            name = "Rigel IOUT1 max pulse count",
            results_name = "RigelIOUT1PC",
            command = "OSDPearlTester RigelIllegalDrive --mode iout1-max-pc --pdcaPath $ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout1_pc.plist",
            timeout = 10, -- a very short test
            pdca_plist_paths = {"$ASTRO_NODE_LOG_DIRECTORY/_pdca_rigel_iout1_pc.plist",}
        },
    }
end
