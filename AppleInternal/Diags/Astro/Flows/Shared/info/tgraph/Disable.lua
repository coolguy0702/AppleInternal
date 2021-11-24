local Shell = require "flow.Shell"

return function()
    return Shell {
        name = "Disable tGraphLogFile",
        results_name = "TGRAPH_DISABLE",
        command = "/usr/local/bin/thermtune --notGraphLogFile"
    }
end
