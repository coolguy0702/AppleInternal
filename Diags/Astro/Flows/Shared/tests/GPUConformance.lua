-- TODO: Documentation
local DebugShell = require 'flowextensions.DebugShell'
local device = require 'device'

return function()
    local soc_gen = device.soc_generation()
    local path = '/AppleInternal/Diags/Tests/AppleSOC/' .. soc_gen .. '/GPU/Conformance/'
    local script_name = 'runMetalTests.sh'

    return DebugShell {
        name = 'GPU Conformance test',
        command = 'pushd ' .. path .. ' && ' .. path .. script_name .. ' && popd'
    }
end
