local astro = require "astro"
local Step = require "flow.Step"
local Exception = require "exceptions.Exception"
local processutils = require "processutils"
local rxburnsemaphore = require 'rxburnsemaphore'

return function()
    return Step {
        name = "RxBurn resume",
        description = "RxBurn resume",

        main = function(self)
            if not rxburnsemaphore.rxburn_started_semaphore_file_exists(astro.environment.WORKING_DIRECTORY) then
                print("RxBurn has not started.")
                self:save_metadata_result {
                    exit_reason = "not started"
                }
                return
            end

            -- OSDNANDTester already protects against calling pause if it's already paused
            local cmd = processutils.launch_exec("/usr/local/bin/OSDNANDTester", {
                "resume"
            })

            -- We saw timeouts at 30 before so let's be generous. We can always profile this later
            local complete, result = cmd:wait_until_exit_or_timeout(60)

            if not complete then
                cmd:kill()
                cmd:wait_until_exit() -- KILL cannot be handled
                error(Exception("RxBurn resume timed out!"))
            end

            if result.code ~= 0 or result.reason ~= 'exit' then
                self:save_metadata_result {
                    exit_code = result.code,
                    exit_reason = result.reason
                }

                error(Exception("RxBurn resume failed!"))
            end
        end
    }
end
