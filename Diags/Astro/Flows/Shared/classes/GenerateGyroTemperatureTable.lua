local astro = require 'astro'
local objects = require 'objects'
local Node = require 'flow.classes.Node'
local processutils = require 'processutils'
local fs = require 'filesystem'
local epcall = require 'exceptions.epcall'
local system = require "system"
local launchd = require 'launchd'
local verify = require 'verify'

local LOCATIOND_PLIST_PATH = '/System/Library/LaunchDaemons/com.apple.locationd.plist'

local GenerateGyroTemperatureTable = objects.Class(Node)

function GenerateGyroTemperatureTable:init(args)
    verify.table(args, "args must be a table!")

    local metadata = {
        name = 'Generate GYTT',
        results_name = 'GYTT',
        description = 'Generate GYTT',
    }

    if args.metadata ~= nil then
        verify.table(args.metadata, "args.metadata must be a table!")
        metadata = args.metadata
    end

    metadata[astro.viz.MetadataKeys.CAUSES_REBOOT] = true

    local representation = astro.viz.Step {
        metadata = metadata
    }

    Node.init(self, representation)

    -- temperature_points is required
    verify.not_nil(args.temperature_points, "args.temperature_points must be provided!")
    verify.number(args.temperature_points, "args.temperature_points must be a number!")
    self.temperature_points = args.temperature_points

    -- gyroHeatingFunciton is also required
    verify.not_nil(args.gyroHeatingFunciton, "args.gyroHeatingFunciton must be provided!")
    verify.func(args.gyroHeatingFunciton, "args.gyroHeatingFunciton must be a function!")
    self.gyroHeatingFunciton = args.gyroHeatingFunciton

    self.upper_limit = nil -- The upper limit that should be applied to the lowest temperature GYTT point

    if args.upper_limit ~= nil then
        verify.number(args.upper_limit, "args.upper_limit must be a number!")
        self.upper_limit = args.upper_limit
    end

    -- delete_existing_GYTT is used to configure the class to not delete the table, useful if you're continuing the
    -- temperature ramp in a second location
    -- Detaults to true, which is to always delete the existing table
    self.delete_existing_GYTT = true

    if args.delete_existing_GYTT ~= nil then
        verify.boolean(args.delete_existing_GYTT, "args.delete_existing_GYTT must be a boolean!")
        self.delete_existing_GYTT = args.delete_existing_GYTT
    end
end

function GenerateGyroTemperatureTable:setup()
    launchd.unload(LOCATIOND_PLIST_PATH)
    local success, err = epcall(function()
        fs.remove('/Library/Caches/locationd')
    end)

    if not success then
        print('Failed to remove /Library/Caches/locationd: ' .. err.message)
    end

    success, err = epcall(function()
        fs.remove('/var/root/Library/Caches/locationd')
    end)

    if not success then
        print('Failed to remove /var/root/Library/Caches/locationd: ' .. err.message)
    end

    launchd.load(LOCATIOND_PLIST_PATH)

    -- Background CoreMotion build GYTT
    processutils.shell('/usr/local/bin/motiontool buildGYTT > /dev/null 2> /dev/null &')
end

function GenerateGyroTemperatureTable:writeResults()
    -- Make the log directory, which BuildGYTT refers to as the "working directory"
    local working_dir =  self:get_log_dir('GYTT')
    fs.mkdirs(working_dir)

    -- Launch the tool that will finalize the results. It may also invoke its own heating systems.
    local buildgytt_path = '/usr/local/bin/BuildGYTT'
    local options = {'-m', tostring(self.temperature_points), '-p', working_dir}

    if self.upper_limit then
        table.insert(options, '-l')
        table.insert(options, tostring(self.upper_limit))
    end

    local buildgytt = processutils.launch_exec(
        buildgytt_path, options
    )

    -- Wait 10 minutes
    local timeout_s = 600
    local complete, result = buildgytt:wait_until_exit_or_timeout(timeout_s)

    if not complete then
        print("BuildGYTT did not complete within " .. timeout_s .. " seconds! Terminating...")

        -- BuildGYTT has a signal handler to properly tear down any of the thermal processes it may have spun up
        -- It will also use this as opportunity to write what it has to the working directory, as well as sysconfig
        processutils.terminate_or_kill(buildgytt)
    end

    -- One of the results of BuildGYTT is a pdca plist in the working directory
    local pdca_path = fs.path.join(working_dir, '_pdca_gytt.plist')

    if fs.is_file(pdca_path) then
        self:save_pdca_plist(pdca_path)
    else
        print('Not importing ' .. pdca_path .. ' because it does not exist')
    end

    -- It also outputs a plist of the points collected
    local gytt_source_plist_path = '/private/var/logs/BurnIn/gytt.plist'

    if fs.is_file(gytt_source_plist_path) then
        -- We should move this file into the astro node log directory
        local gytt_destination_plist_path = fs.path.join(working_dir, 'gytt.plist')
        fs.move(gytt_source_plist_path, gytt_destination_plist_path)

        self:save_file_result {
            path = gytt_destination_plist_path,
            metadata = {
                description = 'GYTT plist'
            }
        }
    else
        print("GYTT plist does not exist at " .. gytt_source_plist_path)
    end

    -- Now it's time to fail the Node if we did indeed fail the BuildGYTT stage

    if not complete then
        error("BuildGYTT did not complete within " .. timeout_s .. " seconds!")
    end

    -- We know we completed if we reached here, else we would have errored above
    if result.reason ~= 'exit' then
        error("BuildGYTT did not exit! Instead, the reason was " .. result.reason)
    end

    -- We know we at least exited at this point
    if result.code == 0 then
        print("BuildGYTT exited successfully with code 0")
    else
        error("BuildGYTT exited with code " .. result.code)
    end
end

function GenerateGyroTemperatureTable:clearGYTTAndReboot()
    -- Initialization to start CoreMotion building GYTT
    processutils.shell('/usr/local/bin/BuildGYTT -d')

    self:save_state {
        started = true
    }

    print("Rebooting...")

    local success, e = epcall(system.reboot)

    if not success then
        print("Failed to reboot system. Cleaning up...")
        error(e)
    end
end

function GenerateGyroTemperatureTable:run()
    -- Only delete if we haven't yet started (re-entered after a reboot)
    if self.delete_existing_GYTT and not self:get_state().started then
        self:clearGYTTAndReboot()
    else
        self:setup()
        self.gyroHeatingFunciton()
        self:writeResults()
    end
end

return GenerateGyroTemperatureTable
