local Step = require 'flow.classes.Step'
local objects = require 'objects'
local processutils = require 'processutils'
local fs = require 'filesystem'
local verify = require 'verify'

local RunH10ISPScript = objects.Class(Step)

function RunH10ISPScript:init(args)
    self.script_path = nil
    self.timeout = 120 -- default timeout
    self.output_file_name = nil
    self.description = ''

    if args ~= nil then
        verify.table(args)
        verify.string(args.script_path)
        self.script_path = args.script_path

        if args.timeout ~= nil then
            verify.number(args.timeout)
            self.timeout = args.timeout
        end

        if args.output_file_name ~= nil then
            verify.string(args.output_file_name)
            self.output_file_name = args.output_file_name
        end

        if args.description ~= nil then
            verify.string(args.description)
            self.description = ' ' .. args.description
        end

    end

    Step.init(self, {
        name = 'Run h10isp Script' .. self.description,
        description = 'Run h10isp Script' .. self.description,
        results_name = 'RunH10ISPScript',
    })
end

function RunH10ISPScript:run_script_at_path(script_path, output_file_name)
    local cmd = '/usr/local/bin/h10isp -s ' .. script_path
    local output_file_path = nil

    if output_file_name ~= nil then
        local working_dir =  self:get_log_dir('RunH10ISPScript')
        processutils.exec("/bin/mkdir", {"-p", working_dir})
        output_file_path = working_dir .. "/" .. output_file_name
        cmd = cmd .. ' > ' .. output_file_path
    end

    local result = processutils.shell(cmd, self.timeout)

    self:save_passfail_result {
        name = 'Run h10isp Script' .. self.description,
        pass = result.code == 0,
        message = "h10isp exited with code " .. result.code
    }

    if result.code ~= 0 then
        processutils.shell('/usr/bin/killall h10isp') -- clean up just in case
    end

    return output_file_path

end

function RunH10ISPScript:main()
    if not fs.is_file(self.script_path) then
        error("h10isp script does not exist at " .. self.script_path)
    end

    local output_file_path = self:run_script_at_path(self.script_path, self.output_file_name)

    if output_file_path ~= nil then
        self:save_file_result {
            path = output_file_path,
            metadata = {
                description = self.output_file_name
            }
        }
    end

end

return RunH10ISPScript
