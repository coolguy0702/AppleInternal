local DebugShell = require 'flowextensions.DebugShell'


return function()
    return DebugShell {
        name = 'H.264 Decoder Tests',
        command = '/usr/local/bin/goldenVideo --source /AppleInternal/Diags/Tests/Common/h264_720p_nasa_10frame.mov --verify /AppleInternal/Diags/Tests/Common/h264_720p_nasa_10frame_refdata.yuv --verbose'
    }
end
