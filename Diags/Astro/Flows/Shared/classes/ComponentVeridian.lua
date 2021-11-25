local objects = require 'objects'
local processutils = require 'processutils'
local fs = require 'filesystem'
local DebugShell = require 'flowextensions.DebugShell'

local ComponentVeridian = objects.Class(DebugShell)

function ComponentVeridian:init(should_reauth)
    local pdca_path_prefix = '/private/var/logs/BurnIn/PDCA'

    -- defaults to reauth if nil or if value is true
    if should_reauth  == false then
        local pdca_path = fs.path.join(pdca_path_prefix, '_pdca_veridian_reboot.plist')

        DebugShell.init(self, {
            name = 'Component Veridian',
            results_name = 'ComponentVeridian',
            command = '/usr/local/bin/OSDRoswell auth --pdcaPath ' ..  pdca_path .. ' --label Reboot --accessory battery',
            pdca_plist_paths = {pdca_path},
            timeout = 30,
        })
    else
        local pdca_path = fs.path.join(pdca_path_prefix, '_pdca_veridian_reauth.plist')
        DebugShell.init(self, {
            name = 'Component Veridian (ReAuth)',
            results_name = 'ComponentVeridianReAuth',
            command = '/usr/local/bin/OSDRoswell auth --reauth --retries 3 --quiesce 1 --pdcaPath ' ..  pdca_path .. ' --label Sleep --accessory battery',
            pdca_plist_paths = {pdca_path},
            timeout = 30,
        })
    end
end

function ComponentVeridian:debug_result(result)
    self:debug_steps()
    DebugShell.debug_result(self, result)
end

function ComponentVeridian:debug_timeout(proc)
    self:debug_steps()
    DebugShell.debug_timeout(self, proc)
end

function ComponentVeridian:debug_steps()
    fs.mkdirs(self:debug_log_dir())
    processutils.shell('/usr/local/bin/OSDToolbox FDR -k vcrt --AMFDRSealingMapCopy --outputPath ' .. fs.path.join(self:debug_log_dir(), 'vcrt_payload.bin'), 30)

end

return ComponentVeridian
