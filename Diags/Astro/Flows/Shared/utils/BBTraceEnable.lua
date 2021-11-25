local Shell = require 'flow.Shell'

return function()
    return Shell {
        name = 'Enable BB Trace',
        command = '/usr/local/bin/abmtool bbtrace enabled true'
    }
end
