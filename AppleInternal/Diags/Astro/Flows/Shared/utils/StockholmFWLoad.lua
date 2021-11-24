local Step = require "flow.Step"
local nfutils = require "nfutils"
local iosdebug = require "iosdebug"
local verify = require "verify"
local processutils = require "processutils"
local fs = require "filesystem"

return function(manufacturing)
    if manufacturing ~= nil then
        verify.boolean(manufacturing, "manufacturing expected a boolean")
    else
        manufacturing = true
    end

    return Step {
        name = manufacturing and "StockholmManufacturing" or "StockholmProduction",
        description = "Load Stockholm " .. (manufacturing and "Manufacturing" or "Production") .. " FW",

        main = function(self)
            nfutils.unload_nf()
            local restore = nfutils.launch_restore_process(manufacturing)
            local complete, result = restore:wait_until_exit_or_timeout(300)
            local debug_dir = self:get_log_dir("Debug/StockholmFW")

            if not complete then
                print("Timed out loading Stockholm Manufacturing FW...")

                fs.mkdirs(debug_dir)
                iosdebug.timeout.save_timeout_results(self, restore, debug_dir)

                print("Killing restore process")
                processutils.terminate_or_kill(restore)

            elseif result.code ~= 0 then
                fs.mkdirs(debug_dir)
                iosdebug.stockholm.save_stockholm_debug_results(self, debug_dir)
            end

            nfutils.load_nf()
        end
    }
end
