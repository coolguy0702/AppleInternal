local DebugShell = require 'flowextensions.DebugShell'
local device = require 'device'

return function()
    local soc_gen = device.soc_generation()
    local module = 'balance'

    if soc_gen == 'H12' then
        module = 'h12'
    end

    return DebugShell {
        name = 'GPU Power Virus',
        command = '/usr/local/bin/agx_power_test execute --module gpu.balance --submodule ' .. module .. ' --thread-count 4194304  --renders-per-cmd-buffer 4 --queues 4 --duration 120'
    }
end
