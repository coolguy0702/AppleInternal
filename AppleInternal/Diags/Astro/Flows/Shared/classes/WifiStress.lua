local astro = require 'astro'
local objects = require 'objects'
local Node = require 'flow.classes.Node'
local corecapture = require 'corecapture'
local wifi_version = require 'versions.wifi'
local iosdebug = require 'iosdebug'
local processutils = require 'processutils'
local verify = require 'verify'
local fs = require 'filesystem'

local TEST_NAME = 'WifiStress'
local WifiStress = objects.Class(Node)

function WifiStress:init(args)
    -- defaults
    local run_prepost_test = false
    local child = nil

    -- required
    verify.number(args.iteration_count, 'Iteration count must be a number')
    verify.number(args.timeout, 'Timeout must be a number')
    local iteration_count = args.iteration_count
    local timeout = args.timeout

    -- optional
    if args then
        if args.run_prepost_test then
            verify.boolean(args.run_prepost_test, 'PrePostTest must be boolean')
            run_prepost_test = args.run_prepost_test
        end

        if args.child then
            if objects.is_instance(args.child, Node) ~= true then
                error('Expected child to be a Node')
            end

            child = args.child
        end
    end


    -- Default we run pre post test commands
    local prepost_arg = ' -runPrePostTestCommands 1'
    if run_prepost_test == false then
        prepost_arg = ' -runPrePostTestCommands 0'
    end

    local metadata = {
        name = TEST_NAME,
        results_name = TEST_NAME,
        description = TEST_NAME .. ' with ' .. iteration_count .. ' iterations, ' .. timeout .. 's timeout',
    }

    local sequence_args = {
        metadata = metadata
    }

    if child then
        if objects.is_instance(child, Node) ~= true then
            error('Expected Node instance in WifiStress')
        end

        self.body = child
        sequence_args.steps = {self.body.representation}
    end

    local representation = astro.viz.Sequence(sequence_args)
    Node.init(self, representation)

    self.command = '/usr/local/bin/QueueStall -iterations ' .. iteration_count .. ' -sleepDuration 0.1' .. prepost_arg
    self.timeout = timeout
end

function WifiStress:debug_log_dir()
    return self:get_log_dir('Debug/WifiStress')
end

function WifiStress:setup()
    self:save_software_attributes {
        wifi_firmware_version = wifi_version()
    }
    print('Checking CoreCapture')
    local did_wifi_previously_crash = corecapture.did_wifi_crash()
    self:save_pdca_records {
        {
            name = 'CoreCapture pre WiFiStress',
            pass = not did_wifi_previously_crash,
            message = 'Found CoreCapture crashes'
        }
    }

    self.cleanup_path = self:debug_log_dir()
    if did_wifi_previously_crash then
        corecapture.wifi_cleanup(self.cleanup_path .. '/CoreCapture/Pretest')
    end

end

function WifiStress:process_timeout(proc)
    fs.mkdirs(self:debug_log_dir())
    iosdebug.timeout.save_timeout_results(self, proc, self:debug_log_dir())
    iosdebug.wifi.save_wifi_debug_results(self, self.cleanup_path)

    proc:wait_until_exit_or_timeout(self.timeout)
end

function WifiStress:process_result(result)
    if result.code ~= 0 then
        iosdebug.wifi.save_wifi_debug_results(self, self.cleanup_path)
        iosdebug.default.save_default_debug_results(self, result, self:debug_log_dir())
    end
end

function WifiStress:teardown()
    print('Checking CoreCapture')
    local did_wifi_crash_after_test = corecapture.did_wifi_crash()
    self:save_pdca_records {
        {
            name = 'CoreCapture post WiFiStress',
            pass = not did_wifi_crash_after_test,
            message = 'Found CoreCapture crashes'
        }
    }

    if did_wifi_crash_after_test then
        corecapture.wifi_cleanup(self.cleanup_path .. '/CoreCapture/Posttest')
    end
end

function WifiStress:setup_command()
    self.proc = processutils.launch_shell(self.command)
end

function WifiStress:teardown_command()
    local complete, result = self.proc:wait_until_exit_or_timeout(self.timeout)

    if complete then
        self:save_passfail_result {
            name = TEST_NAME,
            pass = result.code == 0,
            message = "Command " .. result.reason .. "ed with code " .. result.code
        }

        self:process_result(result)
    else
        self:save_metadata_result {
            exit_reason = 'timeout'
        }

        self:save_passfail_result {
            name = TEST_NAME,
            pass = false,
            message = "Command timed out after " .. self.timeout .. "second(s)"
        }

        self:process_timeout(self.proc)
    end
end

function WifiStress:run()
    self:setup()
    self:setup_command()

    if self.body then
        self.body()
    end

    self:teardown_command()
    self:teardown()

end

return WifiStress
