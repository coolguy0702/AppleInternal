local GenerateGyroTemperatureTable = require 'classes.GenerateGyroTemperatureTable'
local objects = require "objects"
local processutils = require 'processutils'

local Class = objects.Class
local GeneratePRTTGyroTemperatureTable = Class(GenerateGyroTemperatureTable)

local BURNIN_DIR_PATH = '/private/var/logs/BurnIn'

function GeneratePRTTGyroTemperatureTable:init(args)
    if args.metadata == nil then
        args.metadata = {
            name = 'Generate GYTT PRTT',
            results_name = 'GYTT',
            description = 'Generate GYTT PRTT',
        }
    end

    GenerateGyroTemperatureTable.init(self, args)
end

function GeneratePRTTGyroTemperatureTable:setup()
    GenerateGyroTemperatureTable.setup(self)

    print('Running buildPRTT while GYTT Heating')
    local prttTag = 'GYTTHeating'
    -- <rdar://problem/49996939>
    processutils.shell(string.format('/usr/local/bin/motiontool buildPRTT %s 0.04 %s/prtt.db Run-%s &> /dev/null &', prttTag, BURNIN_DIR_PATH, prttTag))
end

return GeneratePRTTGyroTemperatureTable
