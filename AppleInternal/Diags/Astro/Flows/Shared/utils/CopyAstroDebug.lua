local astro = require 'astro'
local flowconfig = require 'flowconfig'
local Sequence = require 'flow.Sequence'
local Shell = require 'flow.Shell'

return function()
    return Sequence {
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        -- Eventually Astro will take care of this for us rdar://56341925
        Shell {
            name = 'Copy Astro Flows folder',
            command = '/bin/cp -r /AppleInternal/Diags/Astro/Flows/ $ASTRO_WORKING_DIRECTORY/Flows/' -- copies Flows folder into Astro folder
        },

        Shell {
            name = 'Record Astro status',
            description = 'Record Astro status',
            results_name = 'Astro Status',
            command = '/usr/local/bin/astro status ' .. astro.environment.FLOW_IDENTIFIER .. ' > $ASTRO_WORKING_DIRECTORY/astroStatus.txt'
        }
    }
end
