local Node = require 'flow.classes.Node'
local objects = require 'objects'
local astro = require 'astro'

local ExitAstro = objects.Class(Node)

function ExitAstro:init()
    local representation = astro.viz.Step {
        metadata = {
            name = 'Exit Astro',
            description = 'Exit Astro',
            results_name = 'ExitAstro'
        }
    }

    Node.init(self, representation)
end

function ExitAstro:run()
    if not self:get_state().started then
        self:save_state {
            started = true
        }
        os.exit(0)
    end

end

return ExitAstro
