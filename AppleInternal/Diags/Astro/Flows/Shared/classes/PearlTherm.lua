local ISPFWLogShell = require 'flowextensions.ISPFWLogShell'
local objects = require "objects"
local fs = require 'filesystem'
local verify = require "verify"

local Class = objects.Class
local PearlTherm = Class(ISPFWLogShell)

-- The tool hard codes these names
local RGB_CSV_FILE = "rgb.csv"
local IR_CSV_FILE = "ir.csv"
local PDCA_ENV_PATH = "$ASTRO_NODE_LOG_DIRECTORY/pdca.plist"

function PearlTherm:init(args)
    verify.table(args, "args should be a table")
    verify.number(args.duration, "args.duration is required and must be a number")
    verify.string(args.counts_and_intervals, "args.counts_and_intervals is required and must be a string")


    local command = "OSDCameraMetadataSampler run "
    if args.bane == true then
        command = command .. "banepearlfcam "
    else
        verify.boolean(args.bane, "args.bane must be a boolean")
        command = command .. "pearlfcam "
    end

    local test_name = "PearlTherm" .. args.duration .. "s"

    ISPFWLogShell.init(self, {
        name = test_name,
        description = "Pearl (Dot Projector + FCAM) Thermal Test " .. args.duration .. "s",
        command = command .. "pearl-therm --pdca-path ".. PDCA_ENV_PATH ..
            " --label " .. test_name .. " --csv-path $ASTRO_NODE_LOG_DIRECTORY " .. args.counts_and_intervals,
        timeout = args.duration * 2, -- duration * 2
        pdca_plist_paths = {PDCA_ENV_PATH}
    })
end

function PearlTherm:teardown()
    ISPFWLogShell.teardown(self)

    local rgbcsvpath = self.environment["ASTRO_NODE_LOG_DIRECTORY"] .. "/" .. RGB_CSV_FILE
    local ircsvpath = self.environment["ASTRO_NODE_LOG_DIRECTORY"] .. "/" .. IR_CSV_FILE

    if fs.is_file(rgbcsvpath) then
        print("RGB CSV found at " .. rgbcsvpath)

        self:save_file_result {
            path = rgbcsvpath,
            metadata = {
                description = "RGB frames csv file"
            }
        }
    else
        print("RGB CSV NOT found at " .. ircsvpath)
    end

    if fs.is_file(ircsvpath) then
        print("IR CSV found at " .. ircsvpath)

        self:save_file_result {
            path = ircsvpath,
            metadata = {
                description = "IR frames csv file"
            }
        }
    else
        print("IR CSV NOT found at " .. ircsvpath)
    end
end

return PearlTherm
