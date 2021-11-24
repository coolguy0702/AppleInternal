local DebugShell = require 'flowextensions.DebugShell'
local device = require 'device'


return function()
    local soc_gen = device.soc_generation()

    return DebugShell {
        name = 'HEVC Decoder Tests',
        command = '/AppleInternal/Diags/Tests/AppleSOC/' .. soc_gen .. '/VideoDecoder/run_VXDAVD_HEVCFactoryTests.sh /AppleInternal/Diags/Tests/AppleSOC/' .. soc_gen .. '/VideoDecoder y'
        -- Cyprus (H11) and newer SOCs contain VP9 in addition to HEVC
    }
end
