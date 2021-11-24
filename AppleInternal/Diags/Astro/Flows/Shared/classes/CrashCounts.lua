local objects = require 'objects'
local Step = require 'flow.Step'
local fs = require 'filesystem'
local debugutils = require 'iosdebug.debugutils'

local CrashCounts = objects.Class(Step)

function CrashCounts:init()
    Step.init(self, {
        name = 'Crash Counts',
        description = 'Log crashes to PDCA',
        results_name = 'CrashCounts'
    })

end

function CrashCounts:main()
    local crash_path = debugutils.astro_crashreporter_dir()
    local num_astro_crashes = 0

    print('Checking ' .. crash_path .. ' for crashes')

    if not fs.path.exists(crash_path) then
        print(crash_path .. ' does not exist')
        num_astro_crashes = 0
    else
        local crash_files = fs.lsdir(crash_path)

        for _, file_path in pairs(crash_files) do
            if string.find(file_path, 'Astro') then
                num_astro_crashes = num_astro_crashes + 1
            end
        end
    end

    self:save_pdca_records {
        {
            name = 'CrashCounts',
            value = num_astro_crashes,
            pass = true
        }
    }
end

return CrashCounts
