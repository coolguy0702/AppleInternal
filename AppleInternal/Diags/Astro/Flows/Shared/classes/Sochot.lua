local objects = require 'objects'
local Node = require 'flow.classes.Node'
local processutils = require 'processutils'
local astro = require 'astro'

local fs = require 'filesystem'

local iEFI_sochot_path = '/AppleInternal/Diags/Logs/Common/Sochot0Log.txt'

local Sochot = objects.Class(Node)

function Sochot:did_iefi_sochot_occur()
    if fs.is_file(iEFI_sochot_path) then
        return true
    end

    return false
end

function Sochot:clean_iefi_sochot(sochot_failure_path)
    -- Move iEFI sochot log to logs
    fs.mkdirs(sochot_failure_path)
    print('Moving ' .. iEFI_sochot_path .. ' to ' .. sochot_failure_path)
    fs.move(iEFI_sochot_path, sochot_failure_path .. '/Sochot0Log.txt')
end

function Sochot:did_detect_pmu_sochot()
    -- TODO once ioreg support is in, we can grab this key without opening ioreg
    local result = processutils.shell("/usr/sbin/ioreg -k IOPMUBootErrorFaults -r |grep IOPMUBootErrorFaults | grep sochot")
    if result.code == 0 then
        return true
    end

    result = processutils.shell("/usr/sbin/ioreg -k IOPMUBootErrorFaults -r | grep IOPMUBootErrorFaults | grep ntc_shdn")
    if result.code == 0 then
        return true
    end
end

function Sochot:clean_pmu_sochot(sochot_failure_path)
    -- Move HangDetectivePMU to logs
    local hangdetective_path = '/var/logs/BurnIn/HangDetectivePMUDump.txt'

    processutils.shell("/usr/local/bin/FactoryBootCheck")
    fs.mkdirs(sochot_failure_path)
    print('Moving ' .. hangdetective_path .. ' to ' .. sochot_failure_path) fs.move(hangdetective_path, sochot_failure_path .. '/HangDetectivePMUDump.txt')
end

-- If SOCHOT file exists, then a SOCHOT occurred
function Sochot:init()
    local name = 'Check for iEFI sochot and sochots stored in PMU'
    local representation = astro.viz.Step {
        metadata = {
            name = name,
            description = name,
            results_name = 'SOCHOT'
        }
    }

    Node.init(self, representation)
end

function Sochot:run()
    local sochot_failure_path = self:get_log_dir('Sochot')
    if self:did_iefi_sochot_occur() then
        self:clean_iefi_sochot(sochot_failure_path)
        error('Sochot detected from iEFI')
    end

    if self:did_detect_pmu_sochot() then
        self:clean_pmu_sochot(sochot_failure_path)
        error('Sochot detected from IOPMUBootErrorFaults')
    end

    self:save_pdca_records {
    {
        name = "Sochot",
        pass = true,
    }
}

end

return Sochot
