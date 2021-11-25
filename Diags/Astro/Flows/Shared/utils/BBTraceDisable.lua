local Shell = require 'flow.Shell'

return function()
    return Shell {
        name = 'Disable BB Trace',
        command = '/usr/local/bin/abmtool bbtrace enabled false'
    }
end
