local Sequence = require 'flow.Sequence'
local Shell = require "flow.Shell"
local Step = require 'flow.Step'
local astro = require 'astro'
local fs = require 'filesystem'

return function()
    return Sequence {
        Step ('Create Astro logs folder if it does not exist', function()
            local astro_logs_dir = fs.path.join(astro.environment.WORKING_DIRECTORY, 'logs')
            if not fs.is_dir(astro_logs_dir) then
                print('Creating folder ' .. astro_logs_dir)
                fs.mkdirs(astro_logs_dir)
            else
                print('Folder ' .. astro_logs_dir .. ' exists')
            end
        end),
        Shell {
            name = "Enable tGraphLogFile",
            results_name = "TGRAPH_ENABLE",
            command = "/usr/local/bin/thermtune --tGraphLogFile $ASTRO_WORKING_DIRECTORY/logs/tgraph.csv -p"
        }
    }
end
