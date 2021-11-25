local Sequence = require 'flow.Sequence'
local Shell = require 'flow.Shell'

return function(log_path)
    -- Provide a default that can run without a param passed (CLI)
    if log_path == nil then log_path = "$ASTRO_WORKING_DIRECTORY/logs/DebugLogs" end

    return Sequence {
        continue_on_fail = true,

        Shell {
            name = 'Create Debug Folder',
            command = '/bin/mkdir -p ' .. log_path
        },
        Shell {
            name = 'ps aux',
            command = '/bin/ps aux> ' .. log_path .. '/ps.txt'
        },
        Shell {
            name = 'Record disk free space',
            command = '/bin/df -h > ' .. log_path .. '/df.txt'
        },
        Shell {
            name = 'NVRAM',
            command = '/usr/sbin/nvram -p > ' .. log_path .. '/nvram.txt'
        },
        Shell {
            name = 'sysconfig',
            command = '/usr/local/bin/sysconfig read -a > ' .. log_path .. '/sysconfig.txt'
        },
        Shell {
            name = 'control bits',
            command = '/usr/local/bin/controlbits read -a > ' .. log_path .. '/controlbits.txt'
        },
        Shell {
            name = 'launchctl list',
            command = '/bin/launchctl list > ' .. log_path .. '/launchctl_list.txt'
        },
        Shell {
            name = 'thermhid',
            command = '/usr/local/bin/thermhid > ' .. log_path .. '/thermhid.txt'
        },
        Shell {
            name = 'hidutil dump',
            command = 'hidutil dump  > ' .. log_path .. '/hidutil_dump.txt'
        },
        Shell {
            name = 'ioreg',
            command = '/usr/sbin/ioreg -w0 -l > ' .. log_path .. '/ioreg.txt'
        },
        Shell {
            name = 'iordump',
            command = '/usr/local/bin/iordump > ' .. log_path .. '/iordump.txt'
        },
        Shell {
            name = 'sysctl',
            command = '/usr/sbin/sysctl -a > ' .. log_path .. '/sysctl.txt'
        },
        Shell {
            name = 'defaults',
            command = '/usr/bin/defaults read > ' .. log_path .. '/defaults.txt'
        },
        Shell {
            name = 'List FDR Keys',
            command = '/bin/ls /System/Library/Caches/com.apple.factorydata > ' .. log_path .. '/fdr_cache.txt'
        },
        Shell {
            name = 'mount',
            command = '/sbin/mount > ' .. log_path .. '/mount.txt'
        },
    }
end
