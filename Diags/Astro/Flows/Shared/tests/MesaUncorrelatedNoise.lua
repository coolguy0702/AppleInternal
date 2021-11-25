local Shell = require 'flow.Shell'

return function()
    return Shell {
        name = "MesaUncorrelatedNoise",
        description = "Mesa Uncorrelated Noise",

        -- MesaCal
        command = "mkdir -p $ASTRO_NODE_LOG_DIRECTORY; /AppleInternal/Applications/SwitchBoard/MesaCal.app/MesaCal uncorrelatedNoise $ASTRO_NODE_LOG_DIRECTORY",

        -- From Earthbound
        timeout = 100,

        pdca_plist_paths = {
            -- Defined by MesaCal
            '$ASTRO_NODE_LOG_DIRECTORY/Mesa-UncorrelatedNoise/MesaBurnIn.plist',
        },
    }
end
