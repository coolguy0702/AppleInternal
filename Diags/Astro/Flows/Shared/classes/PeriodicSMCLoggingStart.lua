local verify = require 'verify'
local objects = require 'objects'
local DebugShell = require 'flowextensions.DebugShell'

local PeriodicSMCLoggingStart = objects.Class(DebugShell)

function PeriodicSMCLoggingStart:init(args)
    local customkeyblacklist = ''
    if args then
        if args.key_blacklist then
            verify.string(args.key_blacklist, 'args.key_blacklist should be a string')
            customkeyblacklist = '-customkeyBlacklist ' .. args.key_blacklist
        end
    end

    DebugShell.init(self, {
        name = "Start Periodic SMC Key Logging",
        command = '/usr/local/bin/smcif -allKeys ' ..
                    '-csv $ASTRO_WORKING_DIRECTORY/periodicSMCLogging.csv ' ..
                    '-noBuffer -csvRdErrValue 0 ' ..
                    customkeyblacklist .. ' &',
        timeout = 30,
    })
end

return PeriodicSMCLoggingStart
