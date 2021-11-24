local Step = require 'flow.Step'
local command_output = require 'command_output'
local fs = require 'filesystem'
local debugutils = require 'iosdebug.debugutils'
local json = require 'json'
local processutils = require 'processutils'
local epcall = require 'exceptions.epcall'

local function panicStringFromJsonFile(path, key)
    -- Need to delete first line since it contains device information outside of json
    local temporary_json_file = '/tmp/asteroids_ios_kp.json'
    processutils.shell('sed "1d" ' .. path .. ' > ' .. temporary_json_file)
    local success, json_contents = epcall(json.load, temporary_json_file)

    if not success then
        print('Unable to load ' .. path)
        return nil
    end

    local entire_panic_string = json_contents[key]

    if entire_panic_string == nil then
        print('Panic string from ' .. path .. ' was empty')
        return nil
    end

    -- only get first line
    return string.gsub(entire_panic_string, '\n.*', '')
end

-- Files checked for
-- 'panic-base-2019-05-23-160612.ips', 'ResetCounter-2019-05-23-160611.ips', 'DumpPanic-2019-05-23-160612.621.ips', '.panic-full-2019-05-23-160612.372.ips'
-- Anything in the /var/mobile/Library/Logs/CrashReporter/Panics folder
return function()
    return Step {
        name = 'Kernel Panic Check',
        description = 'Kernel Panic Check',
        main = function(self)
            -- Check boot faults to help see if device ewas rebooted after a panic
            local boot_faults = command_output('/usr/sbin/ioreg -r -k IOPMUBootErrorFaults | grep BootErrorFaults', 30)
            print('Boot faults: ' .. boot_faults)

            -- Check if we were low battery since it can look like a kernel panic
            local battery_percent_string = command_output("/usr/local/bin/smcif -read BRSC | awk '{print $3}'", 30)
            print('Battery percent: ' .. battery_percent_string)

            -- Check CrashReporter folder for files starting with panic-*.ips
            local file_list = fs.lsdir(debugutils.crash_reporter_dir) for _, filename in pairs(file_list) do
                local found_panic_file = false
                local file_path = fs.path.join(debugutils.crash_reporter_dir, filename)
                local panic_string = nil

                if string.find(filename, '^panic%-.*%.ips') then
                    panic_string = panicStringFromJsonFile(file_path, 'panicString')
                    print('Found panic file ' .. filename .. ' with panic string ' .. tostring(panic_string))

                    if panic_string then
                        self:save_passfail_result {
                            name = 'Panic',
                            pass = false,
                            message = panic_string
                        }
                    else
                        self:save_passfail_result {
                            name = 'UnknownPanic',
                            pass = false,
                            message = 'No panic string'
                        }
                    end
                    found_panic_file = true

                elseif string.find(filename, '^%.panic%-.*%.ips') or string.find(filename, '^DumpPanic%-.*%.ips') then
                    -- this is incomplete panics written to disk, since panics should be done by the time this runs, this is due to cleanup not complete
                    print('Found related panic file ' .. filename)
                    found_panic_file = true
                elseif string.find(filename, '^forceReset%-.*%.ips') then
                    panic_string = panicStringFromJsonFile(file_path, 'string')
                    print('Found force reset file ' .. filename .. ' with panic string ' .. tostring(panic_string))
                    found_panic_file = true
                    self:save_passfail_result {
                        name = 'ForceReset',
                        pass = false,
                        message = panic_string
                    }
                end

                if found_panic_file then
                    local destination_folder = self:get_log_dir('Debug/KernelPanic')
                    local destination_file = fs.path.join(destination_folder, fs.path.basename(file_path, nil))

                    fs.mkdirs(destination_folder)
                    fs.move(file_path, destination_file)
                    self:save_file_result {
                        path = destination_file,
                        metadata = {
                            description = 'Kernel Panic: ' .. (panic_string or 'unknown')
                        }
                    }

                    file_path = fs.path.join(debugutils.crash_reporter_dir, 'Panics')
                    destination_file = fs.path.join(destination_folder, 'Panics')
                    if fs.path.exists(file_path) then
                        fs.move(file_path, destination_file)
                        self:save_file_result {
                            path = destination_file,
                            metadata = {
                                description = 'Panic folder'
                            }
                        }
                    end

                    self:save_parametric_result {
                        name = {'Panic Detected - Battery Percent'},
                        value = tonumber(battery_percent_string),
                        limit = {
                            upper = nil,
                            lower = nil,
                        },
                        units = '%',
                    }
                end
            end
        end
    }
end
