-- <rdar://problem/48899749>
local verify = require 'verify'
local PRTTShell = require 'classes.PRTTShell'

local DATABASE_PATH = '/var/logs/BurnIn/prtt.db'
local WRITE_PRTT_PDCA_PATH = '/private/var/logs/BurnIn/PDCA/osdmotiontesterwriteprtt.plist'

return function(args)
    local writeSyscfg = false
    local writeSyscfgValue = 'NO'

    if args ~= nil then
        verify.table(args, 'args should be a table')

        if args.writeSyscfg ~= nil then
            verify.boolean(args.writeSyscfg, 'writeSyscfg should be a boolean')
            writeSyscfg = args.writeSyscfg
        end

    end

    if writeSyscfg then
        writeSyscfgValue = 'YES'
    end

    return PRTTShell {
            name = 'Write PRTT. Write Sysconfig Key: ' .. writeSyscfgValue,
            results_name = 'WritePRTT',
            command = '/usr/local/bin/OSDMotionTester WritePRTT --writeSyscfg=' .. writeSyscfgValue .. ' --databasePath=' .. DATABASE_PATH ..' --pdcaPath=' .. WRITE_PRTT_PDCA_PATH,
            timeout = 30,
            pdca_plist_paths = {WRITE_PRTT_PDCA_PATH},
    }
end
