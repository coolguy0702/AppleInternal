local objects = require "objects"
local Class = objects.Class
local DebugShell = require 'flowextensions.DebugShell'
local fs = require 'filesystem'
local iosdebug = require 'iosdebug'

local MipiFileCleanupShell = Class(DebugShell)

function MipiFileCleanupShell:teardown()
    DebugShell.teardown(self) -- Have DebugShell do teardown first

    local destination_path = self:get_log_dir(self.node_log_dir_name)
    local parent_path = '/private/var/logs/BurnIn'

    local success, files = self:call_and_report_error(
        iosdebug.debugutils.move_files_matching,
        "_BERtest_",
        parent_path,
        destination_path
    )

    if success then
        for _, file in pairs(files) do
            self:save_file_result {
                path = file,
                metadata = {
                    description = "BER log file"
                }
            }
        end
    end

    local pdca_path = fs.path.join(parent_path, 'PDCA')
    success, files = self:call_and_report_error(
        iosdebug.debugutils.move_files_matching,
        "_BurninTest",
        pdca_path,
        destination_path
    )

    if success then
        for _, file in pairs(files) do
            self:save_file_result {
                path = file,
                metadata = {
                    description = "PHY BurnIn PDCA file"
                }
            }
        end
    end
end

return MipiFileCleanupShell
