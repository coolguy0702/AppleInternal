-- Astro libraries
local Sequence = require "flow.Sequence"
local ISPFWLogShell = require "flowextensions.ISPFWLogShell"
local Step = require "flow.Step"

-- Other libraries
local processutils = require "processutils"
local fs = require "filesystem"

local SCRIPT_PATH = "/AppleInternal/Diags/OSScripts/Peace/JulietSHA/"
local PLIST_PATH = "/private/var/logs/BurnIn/PDCA/_pdca_JU_SHA_TEST.plist"

local function JulietSHA()
    return Sequence {
        description = "JulietSHA test and cleanup",

        ISPFWLogShell {
            name = "JulietSHA",
            command = "pushd " .. SCRIPT_PATH .. " && ./run_ju_sha_test.bash && popd",
            pdca_plist_paths = {PLIST_PATH}
        },

        Step {
            name = "JulietSHA", -- Use the same name so we get the same logs directory
            description = "Move the JulietSHA files",
            main = function(self)
                local log_dir = self:get_log_dir(self.metadata.name) -- "JulietSHA"

                -- Best effort to move the pdca file out of the BurnIn path, which is hard coded to this test
                if fs.is_file(PLIST_PATH) then
                    processutils.exec("/bin/mkdir", {"-p", log_dir})
                    processutils.exec("/bin/mv", {PLIST_PATH, log_dir .. "/pdca.plist"})
                end

                -- Now move the log file "log_ju_sha_test.log"
                local log_file = SCRIPT_PATH .. "log_ju_sha_test.log"
                if fs.is_file(log_file) then
                    processutils.exec("/bin/mkdir", {"-p", log_dir})
                    processutils.exec("/bin/mv", {log_file, log_dir})
                end
            end
        },
    }
end

return JulietSHA
