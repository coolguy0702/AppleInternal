-- TODO loop through possible aggressors instead of manually adding
local Shell = require 'flow.Shell'
local Step = require 'flow.Step'
local Sequence = require 'flow.Sequence'
local flowconfig = require 'flowconfig'
local grape_version = require 'versions.grape'

-- TODO <rdar://problem/45936769> Asteroids_iOS add thermal precondition support
return function()
    return Sequence {
        name = "PhosOrb Aggressors Setup",
        description = "Set up PhosOrb registers",
        results_name = "PhosOrb Aggressors Setup",
        continue_on_fail = false, -- This is always failing since we must have registers set properly before running our tests

        on_enter = {
            Step('Save Grape FW version', function (self)
                self:save_software_attributes {
                    grape_firmware_version = grape_version()
                }
            end)
        },
        Shell {
            name = 'Enable Grape diagnostic active mode (120Hz scan)',
            command = '/usr/local/bin/mtreport set 0xf3 0xa',
        },
        Shell {
            name = 'Disable Grape Noise Avoidance',
            command = '/usr/local/bin/mtreport set 0xa8 0x0',
        },
        Shell {
            name = 'Grape output image type to raw',
            command = '/usr/local/bin/mtreport set 0xa5 0x0',
        },
        Shell {
            name = 'Disable Grape baseline adaptation, low frequency Grape scan',
            command = '/usr/local/bin/mtreport hset 41 01 40',
        },
        Shell {
            name = 'Select Shaké scan config',
            command = '/usr/local/bin/mtreport set 0x20 0x2',
        },
        Shell {
            name = 'Create PhosOrb log folder',
            command = '/bin/mkdir -p $ASTRO_WORKING_DIRECTORY/PhosOrb',
        },

        Sequence {
            name = "PhosOrb Aggressors",
            description = "Perform PhosOrb calibration for various aggressors",
            results_name = "PhosOrb Aggressors",
            continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

            Shell {
                name = 'PhosOrb Baseline',
                command = '/usr/local/bin/OSDOTester PhosOrbAggressors --hdf5=$ASTRO_WORKING_DIRECTORY/PhosOrb/Baseline.h5 -a Baseline',
    --            pdca_plist_paths = {pdca_file} -- TODO
            },
            Shell {
                name = 'PhosOrb SOC 60%',
                command = '/usr/local/bin/OSDOTester PhosOrbAggressors --hdf5=$ASTRO_WORKING_DIRECTORY/PhosOrb/SOC60.h5 -a SOC60',
    --            pdca_plist_paths = {pdca_file} -- TODO
            },
            Shell {
                name = 'PhosOrb SOC 100%',
                command = '/usr/local/bin/OSDOTester PhosOrbAggressors --hdf5=$ASTRO_WORKING_DIRECTORY/PhosOrb/SOC100.h5 -a SOC100',
    --            pdca_plist_paths = {pdca_file} -- TODO
            },
            Shell {
                name = 'PhosOrb SOC 100% + DDR',
                command = '/usr/local/bin/OSDOTester PhosOrbAggressors --hdf5=$ASTRO_WORKING_DIRECTORY/PhosOrb/SOC100_DDR.h5 -a SOC100_DDR',
    --            pdca_plist_paths = {pdca_file} -- TODO
            },
            Shell {
                name = 'PhosOrb Display',
                command = '/usr/local/bin/OSDOTester PhosOrbAggressors --hdf5=$ASTRO_WORKING_DIRECTORY/PhosOrb/Display.h5 -a Display',
    --            pdca_plist_paths = {pdca_file} -- TODO
            },
        }
    }
end
