local Step = require 'flow.classes.Step'

local processutils = require 'processutils'
local fs = require 'filesystem'
local iosdebug = require 'iosdebug'

local ISP_FW_LOG_SCRIPT_PATH = "/tmp/h10isp-forget-script.txt"

-- TODO: Make this work with all hxisp tools
return function()
    return Step {
        name = "H10ISP Forget",
        description = "Run forget in h10isp",

        main = function(self)
            processutils.shell(string.format('echo "forget\nquit\n" > %s', ISP_FW_LOG_SCRIPT_PATH))

            print("Running h10isp forget...")

            local h10isp = processutils.launch_shell("/usr/local/bin/h10isp -n -s " .. ISP_FW_LOG_SCRIPT_PATH)
            local complete, _ = h10isp:wait_until_exit_or_timeout(10)

            if not complete then
                print("Timed out after 10s...")

                local debug_dir = self:get_log_dir("Debug/H10ISPForget")
                fs.mkdirs(debug_dir)
                iosdebug.timeout.save_timeout_results(self, h10isp, debug_dir)

                print("Killing h10isp")
                processutils.terminate_or_kill(h10isp)
            end
        end
    }
end
