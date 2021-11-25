local astro = require 'astro'
local objects = require 'objects'
local Node = require 'flow.classes.Node'
local iosdebug = require 'iosdebug'
local processutils = require 'processutils'
local verify = require 'verify'
local fs = require 'filesystem'
local time = require 'time'

local DATABASE_PATH = '/var/logs/BurnIn/prtt.db'
local TEST_NAME = 'PRTTBackground'
local PRTTBackground = objects.Class(Node)

function PRTTBackground:init(args)
    -- defaults
    local child = nil

    -- required
    verify.number(args.duration, 'duration must be a number')
    verify.string(args.prttTag, 'prttTag must be a number')

    self.duration = args.duration
    self.prttTag = args.prttTag

    -- optional
    if args then
        if args.child then
            if objects.is_instance(args.child, Node) ~= true then
                error('Expected child to be a Node')
            end

            child = args.child
        end
    end

    local metadata = {
        name = TEST_NAME,
        results_name = TEST_NAME,
        description = TEST_NAME .. ' - ' .. self.prttTag .. ', duration, ' .. self.duration.. 's',
    }

    local sequence_args = {
        metadata = metadata
    }

    if child then
        if objects.is_instance(child, Node) ~= true then
            error('Expected Node instance in PRTTBackground')
        end

        self.body = child
        sequence_args.steps = {self.body.representation}
    end

    local representation = astro.viz.Sequence(sequence_args)
    Node.init(self, representation)

end

function PRTTBackground:debug_log_dir()
    return self:get_log_dir('Debug/' .. TEST_NAME)
end

function PRTTBackground:setup()
    self.debug_path = self:debug_log_dir()
    fs.mkdirs(self.debug_path)

    -- Background buildPRTT
    -- '/usr/local/bin/motiontool buildPRTT ${prttTag}_Heating 0.04 /private/var/logs/BurnIn/prtt.db Run-${prttTag}_Heating &> /dev/null &'
    local build_prtt_cmd = string.format('/usr/local/bin/motiontool buildPRTT %s 0.04 %s Run-%s &> /dev/null &', self.prttTag, DATABASE_PATH, self.prttTag)
    processutils.shell(build_prtt_cmd)

    local t = os.date('*t') -- time now
    local time_label = table.concat({t.year, string.format('%02d', t.month), string.format('%02d', t.day), string.format('%02d', t.hour), string.format('%02d', t.min), string.format('%02d', t.sec)}, "-")
    local pressure_logging_cmd = string.format('/usr/local/bin/pressureTester --duration ' .. (self.duration + 30) .. ' --interval 0.04 --printTemperature >%s/pressureTester_heating_%s_%s.log &', self.debug_path, self.prttTag, time_label) -- add 30s to duration for cleanup time
    processutils.shell(pressure_logging_cmd)
end

function PRTTBackground:process_timeout(proc)
    fs.mkdirs(self:debug_log_dir())
    iosdebug.timeout.save_timeout_results(self, proc, self:debug_log_dir())

    proc:wait_until_exit_or_timeout(self.timeout)
end

function PRTTBackground:process_result(result)
    if result.code ~= 0 then
        iosdebug.default.save_default_debug_results(self, result, self:debug_log_dir())
    end
end

function PRTTBackground:teardown()
    print('Wait 30 more seconds to finish pressure logging')
    time.sleep(30)

    processutils.shell('/usr/bin/killall motiontool') -- Killall buildPRTT Heating

    fs.copy('/var/logs/BurnIn/CoreMotion', fs.path.join(self.debug_path, 'CoreMotion'))
end

function PRTTBackground:run()
    self:setup()

    if self.body then
        self.body()
    end

    self:teardown()

end

return PRTTBackground
