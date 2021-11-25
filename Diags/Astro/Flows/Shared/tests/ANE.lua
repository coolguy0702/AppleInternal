local DebugShell = require 'flowextensions.DebugShell'
local device = require 'device'

return function()
    local soc_gen = device.soc_generation()
    local path = string.format('/AppleInternal/Diags/Tests/AppleSOC/%s/ANE/', soc_gen)
    local script_name = 'runTests.sh'

    return DebugShell {
        name = 'ANE Tests',
        command = 'pushd ' .. path .. ' && ' .. path .. script_name .. ' && popd'
    }
end
