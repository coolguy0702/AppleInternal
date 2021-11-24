local verify = require 'verify'
local MesaTestShell = require 'classes.MesaTestShell'

return function(config)
    local suffix = ""

    if config ~= nil then
        if config['initial_run'] ~= nil then
            verify.boolean(config['initial_run'], "config['initial_run'] expected a boolean")
            if config['initial_run'] then
                suffix = "-initial 1"
            end
        end
    end

    return MesaTestShell {
        name = 'Component Mesa ' .. suffix,
        command = '/usr/local/bin/Component -check mesa ' .. suffix,
    }
end
