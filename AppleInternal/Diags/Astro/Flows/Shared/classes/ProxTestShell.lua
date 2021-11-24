local objects = require "objects"
local DebugShell = require 'flowextensions.DebugShell'
local processutils = require 'processutils'
local fs = require 'filesystem'

local ProxTestShell = objects.Class(DebugShell)

local function run_command_with_timeout(command, timeout)
    local process = processutils.launch_shell(command)
    local complete, result = process:wait_until_exit_or_timeout(10)

    if not complete then
        print("Process timed out after " .. timeout .. " seconds")
        processutils.terminate_or_kill(process)
    else
        print(command .. " exited with code " .. result.code)
    end
end

function ProxTestShell:debug_actions()
    print("hidreport list:")
    run_command_with_timeout("/usr/local/bin/hidreport list", 10)

    print("Doppler state:")
    run_command_with_timeout("/usr/local/bin/hidreport -usage 0xFF00,0x0008 get 0xF2", 10)

    print("Doppler detection state:")
    run_command_with_timeout("/usr/local/bin/hidreport -usage 0xFF00,0x0008 get 0x50", 10)

    print("Doppler stream state:")
    run_command_with_timeout("/usr/local/bin/hidreport -usage 0xFF00,0x0008 get 0x51", 10)

    print("Component prox:")
    run_command_with_timeout("/usr/local/bin/Component -check prox", 10)

    print("Doppler state again:")
    run_command_with_timeout("/usr/local/bin/hidreport -usage 0xFF00,0x0008 get 0xF2", 10)

    print("Doppler detection state again:")
    run_command_with_timeout("/usr/local/bin/hidreport -usage 0xFF00,0x0008 get 0x50", 10)

    print("Doppler stream state again:")
    run_command_with_timeout("/usr/local/bin/hidreport -usage 0xFF00,0x0008 get 0x51", 10)

    local prox_sample_file = '/private/var/logs/BurnIn/component_prox.txt'
    if fs.is_file(prox_sample_file) then
        local debug_path = self:debug_log_dir()
        local prox_astro_path = fs.path.join(debug_path, 'component_prox.txt')
        fs.mkdirs(debug_path)
        fs.copy(prox_sample_file, prox_astro_path)
        self:save_file_result {
            path = prox_astro_path,
            metadata = {
                description = 'Prox astro path'
            }
        }
    end
end

function ProxTestShell:debug_result(result)
    self:debug_actions()
    DebugShell.debug_result(self, result)
end

function ProxTestShell:debug_timeout(proc)
    DebugShell.debug_timeout(self, proc)
    self:debug_actions()
end

return ProxTestShell
