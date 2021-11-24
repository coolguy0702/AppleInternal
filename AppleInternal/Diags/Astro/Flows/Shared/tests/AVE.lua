local DebugShell = require 'flowextensions.DebugShell'
local device = require 'device'

return function()
    local soc_gen = device.soc_generation()

    return DebugShell {
        name = 'Video Encoder Tests',
        command = '/AppleInternal/Diags/Tests/AppleSOC/' .. soc_gen ..'/AVE/runGoldenAVE2Factory.sh /AppleInternal/Diags/Tests/AppleSOC/' .. soc_gen ..'/AVE/'
    }
end
