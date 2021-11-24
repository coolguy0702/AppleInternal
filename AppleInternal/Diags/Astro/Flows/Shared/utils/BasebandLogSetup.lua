local Sequence = require 'flow.Sequence'
local Shell = require 'flow.Shell'
local flowconfig = require 'flowconfig'
local verify = require 'verify'

return function(args)
    if args == nil then
        args = {
            -- required
            coredump_enabled = true,
            disable_compression = true,
            background_trace_enabled = true,
            bbtrace_enabled = true,
            reduced_system_logs = true,
            rfs_sync = true,

            -- optional
            maxlog = nil,
        }
    end

    verify.table(args, "args must be a table!")

    local sequence = {
        name = "Baseband Log Setup",
        description = "Set factory baseband logging",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),
    }

    verify.boolean(args.coredump_enabled, "args.coredump_enabled is required and must be a bool!")
    table.insert(sequence, Shell {
        name = "Enable BB Core Dump Logs",
        command = "/usr/local/bin/abmtool coredump enabled " .. tostring(args.coredump_enabled),
    })

    if args.maxlog ~= nil then
        verify.number(args.maxlog, "args.maxlog must be a number!")
        table.insert(sequence, Shell {
            name = "Limit BB Core Dumps to " .. tostring(args.maxlog),
            command = "/usr/local/bin/abmtool trace filter add maxlog " .. tostring(args.maxlog),
        })
    end

    verify.boolean(args.disable_compression, "args.disable_compression is required and must be a bool!")
    if args.disable_compression == true then
        table.insert(sequence, Shell {
            name = "Disable baseband log compression",
            command = "/usr/local/bin/abmtool compression mode off",
        })
    end

    verify.boolean(args.background_trace_enabled, "args.background_trace_enabled is required and must be a bool!")
    if args.background_trace_enabled == true then
        table.insert(sequence, Shell {
            name = "Disable ABM BB Trace",
            command = "/usr/local/bin/abmtool bbtrace enabled false",
        })
        table.insert(sequence, Shell {
            name = "Enable background trace", -- Originated from ICE19
            command = '/usr/local/bin/abmtool trace set basebandtrace backgroundmode 1'
        })
    end

    verify.boolean(args.bbtrace_enabled, "args.bbtrace_enabled is required and must be a bool!")
    table.insert(sequence, Shell {
        name = args.bbtrace_enabled and "Enable ABM BB Trace" or "Disable ABM BB Trace",
        command = "/usr/local/bin/abmtool bbtrace enabled " .. tostring(args.bbtrace_enabled),
    })

    verify.boolean(args.reduced_system_logs, "args.reduced_system_logs is required and must be a bool!")
    if args.reduced_system_logs == true then
        table.insert(sequence, Shell {
            name = "Reduced system logs",
            command = "/usr/local/bin/abmtool trace set systemlogs mode 1",
        })
    end

    verify.boolean(args.rfs_sync, "args.rfs_sync is required and must be a bool!")
    if args.rfs_sync == true then
        table.insert(sequence, Shell {
            name = "Baseband sync remote filesystem",
            command = "/usr/local/bin/abmtool rfs sync",
        })
    end

    return Sequence(sequence)
end
