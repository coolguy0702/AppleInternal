local astro = require "astro"
local Step = require "flow.Step"
local Exception = require "exceptions.Exception"
local processutils = require "processutils"
local fs = require 'filesystem'
local verify = require 'verify'
local rxburnsemaphore = require 'rxburnsemaphore'

return function(subsubtestname)
    if subsubtestname then verify.string(subsubtestname) end

    return Step {
        name = "RxBurn progress",
        description = "RxBurn progress",
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

            local pdca_path = log_dir .. "/progress.plist"
            local args

            if subsubtestname then
                args = {
                    "getProgress",
                    "--pdca=" .. pdca_path,
                    "--label=" .. subsubtestname
                }
            else
                args = {
                    "getProgress",
                    "--pdca=" .. pdca_path
                }
            end

            local cmd = processutils.launch_exec("/usr/local/bin/OSDNANDTester", args)

            -- We saw timeouts at 30 before so let's be generous. We can always profile this later
            local complete, result = cmd:wait_until_exit_or_timeout(60)

            if not complete then
                cmd:kill()
                cmd:wait_until_exit() -- KILL cannot be handled
                error("RxBurn getProgress timed out!")
            end

            if result.code ~= 0 or result.reason ~= 'exit' then
                self:save_metadata_result {
                    exit_code = result.code,
                    exit_reason = result.reason
                }

                error(Exception("RxBurn getProgress failed!"))
            end

            if fs.is_file(pdca_path) then
                self:save_pdca_plist(pdca_path)
            else
                error(Exception("RxBurn getProgress data missing!"))
            end
        end
    }
end
