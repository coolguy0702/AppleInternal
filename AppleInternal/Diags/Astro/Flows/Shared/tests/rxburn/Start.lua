local astro = require "astro"
local Step = require "flow.Step"
local Exception = require "exceptions.Exception"
local processutils = require "processutils"
local rxburnsemaphore = require 'rxburnsemaphore'

return function()
    return Step {
        name = "RxBurn start",
        description = "RxBurn start",

        main = function(self)
            if rxburnsemaphore.rxburn_started_semaphore_file_exists(astro.environment.WORKING_DIRECTORY) then
                print("RxBurn has already started!")
                self:save_metadata_result {
                    exit_reason = "already started"
                }
                return
            end

            local cmd = processutils.launch_exec("/usr/local/bin/OSDNANDTester", {
                "start"
            })

            local complete, result = cmd:wait_until_exit_or_timeout(30)

            if not complete then
                cmd:kill()
                cmd:wait_until_exit() -- KILL cannot be handled
                error(Exception("RxBurn start timed out!"))
            end

            if result.code ~= 0 or result.reason ~= 'exit' then
                self:save_metadata_result {
                    exit_code = result.code,
                    exit_reason = result.reason
                }

                error(Exception("RxBurn start failed!"))
            end

            rxburnsemaphore.write_rxburn_started_semaphore_file(astro.environment.WORKING_DIRECTORY)
        end
    }
end
