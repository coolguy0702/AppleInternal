-- TODO: Documentation
local DebugShell = require 'flowextensions.DebugShell'
local device = require 'device'

return function()
    local soc_gen = device.soc_generation()
    local path = '/AppleInternal/Diags/Tests/AppleSOC/' .. soc_gen .. '/GPU/SEGGPUTests/'
    local script_name = 'run_fugue.sh'

    return DebugShell {
        name = 'Fugue test',
        command = 'pushd ' .. path .. ' && ' .. path .. script_name .. ' && popd'}
end
