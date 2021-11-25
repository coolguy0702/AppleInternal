local Sleep = require 'flow.Sleep'

local astro = require 'astro'
local objects = require 'objects'
local processutils = require 'processutils'
local sysctl = require 'sysctl'
local epcall = require 'exceptions.epcall'
local fs = require 'filesystem'

local SleepWithChecks = objects.Class(Sleep)

-- Used for debugging
--function SleepWithChecks:wokeSuccessful()
--    Sleep.wokeSuccessful(self)
--    local time = require 'time'
--    time.sleep(5)
--end

function SleepWithChecks:run()
    Sleep.run(self)

    local log_dir = self:get_log_dir('SleepCycler')
    epcall(function()
        local wake_reason = sysctl.read('kern.wakereason')

        if string.match(wake_reason, 'baseband') then
            print('Baseband woke up the AP, printing baseband wake reason')
            local bb_path = fs.path.join(log_dir, 'baseband_pcie_wake.txt')
            processutils.shell('/usr/local/bin/abmtool bb wake > ' .. bb_path, 30)
            self:save_file_result {
                path = bb_path,
                metadata = {
                    description = 'Baseband PCIe wake reason'
                }
            }
        end
    end)

    epcall(function()
        local results = self:get_results()

        for _, result in ipairs(results) do
            if result.type == astro.ResultTypes.PARAMETRIC then
                for _, name in pairs(result.contents.name) do
                    if string.find(name, 'S2R') then
                        if result.contents.pass == false then
                            print('Device did not enter S2R, printing SMC keys')

                            local smc_keys_path = fs.path.join(log_dir, 'smc_keys.txt')
                            processutils.shell('/usr/local/bin/smcif -allkeys > ' .. smc_keys_path, 30)
                            self:save_file_result {
                                path = smc_keys_path,
                                metadata = {
                                    description = 'SMC keys'
                                }
                            }
                        end
                    end
                end
            end
        end

    end)
end

return SleepWithChecks
