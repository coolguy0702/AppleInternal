local astro = require "astro"
local Step = require "flow.Step"
local Exception = require "exceptions.Exception"
local processutils = require "processutils"
local verify = require "verify"
local fs = require "filesystem"
local rxburnsemaphore = require 'rxburnsemaphore'

return function(max_wait, polling_interval)
    if max_wait then verify.number(max_wait) end
    if polling_interval then verify.number(polling_interval) end

    return Step {
        name = "RxBurn complete",
        description = "RxBurn waitForFinish and saveResults",

        main = function(self)
            if not rxburnsemaphore.rxburn_started_semaphore_file_exists(astro.environment.WORKING_DIRECTORY) then
                print("RxBurn has not started.")
                self:save_metadata_result {
                    exit_reason = "not started"
                }
                return
            end

            local log_dir = self:get_log_dir("RxBurn")
            fs.mkdirs(log_dir)

            local wait_pdca_path = log_dir .. "/waitForFinish.plist"
            local args = {
                "waitForFinish",
                "--pdca=" .. wait_pdca_path,
                "--maxWait=" .. (max_wait or "36000"),
                "--pollingInterval=" .. (polling_interval or 1)
            }

            local cmd = processutils.launch_exec("/usr/local/bin/OSDNANDTester", args)

            -- We can always profile this later
            local complete, result = cmd:wait_until_exit_or_timeout(37000)

            if not complete then
                cmd:kill()
                cmd:wait_until_exit() -- KILL cannot be handled
                error(Exception("RxBurn waitForFinish timed out!"))
            end

            if result.code ~= 0 or result.reason ~= 'exit' then
                self:save_metadata_result {
                    exit_code = result.code,
                    exit_reason = result.reason
                }

                error(Exception("RxBurn waitForFinish failed!"))
            end

            if fs.is_file(wait_pdca_path) then
                self:save_pdca_plist(wait_pdca_path)
            else
                error(Exception("RxBurn waitForFinish data missing!"))
            end

            local pdca_path = log_dir .. "/saveResults.plist"
            local log_path = astro.environment.WORKING_DIRECTORY .. "/rxburn.log.txt"
            args = {
                "saveResults",
                "--pdca=" .. pdca_path,
                "--logPath=" .. log_path
                -- The rest of the configuration is baked into OSDNANTester
            }

            cmd = processutils.launch_exec("/usr/local/bin/OSDNANDTester", args)

            -- We can always profile this later
            complete, result = cmd:wait_until_exit_or_timeout(30)

            self:save_file_result {
                path = log_path,
                metadata = {
                    description = "RxBurn log"
                }
            }

            if not complete then
                cmd:kill()
                cmd:wait_until_exit() -- KILL cannot be handled
                error("RxBurn saveResults timed out!")
            end

            if result.code ~= 0 or result.reason ~= 'exit' then
                self:save_metadata_result {
                    exit_code = result.code,
                    exit_reason = result.reason
                }

                error(Exception("RxBurn saveResults failed!"))
            end

            -- write this as soon as we know the command succeeded
            rxburnsemaphore.write_rxburn_complete_semaphore_file(astro.environment.WORKING_DIRECTORY)

            if fs.is_file(pdca_path) then
                self:save_pdca_plist(pdca_path)
            else
                error(Exception("RxBurn saveResults data missing!"))
            end
        end
    }
end
