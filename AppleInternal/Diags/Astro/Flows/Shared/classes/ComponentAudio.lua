local DebugShell = require 'flowextensions.DebugShell'
local spu_version = require 'versions.spu'

local objects = require 'objects'
local processutils = require 'processutils'
local fs = require 'filesystem'
local launchd = require 'launchd'
local time = require 'time'
local mediaremoted_plist = '/System/Library/LaunchDaemons/com.apple.mediaremoted.plist'

local ComponentAudio = objects.Class(DebugShell)

function ComponentAudio:init()
    DebugShell.init(self, {
        name = 'audioDeviceTest FactoryTest',
        command = '/usr/local/bin/audioDeviceTest -t FactoryTest',
        timeout = 30,
    })
end

function ComponentAudio:setup()
    DebugShell.setup(self) -- Have DebugShell do setup first

    self:save_software_attributes {
        spu_firmware_version = spu_version()
    }
end

function ComponentAudio:teardown()
    DebugShell.teardown(self)
    print('Unloading ' .. mediaremoted_plist)
    launchd.unload(mediaremoted_plist)
    time.sleep(2)
    print('Loading ' .. mediaremoted_plist)
    launchd.load(mediaremoted_plist)
end

function ComponentAudio:debug_result(result)
    self:debug_actions()
    DebugShell.debug_result(self, result)
end

function ComponentAudio:debug_timeout(proc)
    self:debug_actions()
    DebugShell.debug_timeout(self, proc)
end

function ComponentAudio:debug_actions()
    fs.mkdirs(self:debug_log_dir())
    local audio_debug_path = fs.path.join(self:debug_log_dir(), 'aopaudctl_dump.txt')
    processutils.shell('/usr/local/bin/aopaudctl --dump > "' .. audio_debug_path .. '"', 60)

    self:save_file_result {
        path = audio_debug_path,
        metadata = {
            description = "AOP Audio Ctl"
        }
    }


end

return ComponentAudio
