local objects = require 'objects'
local Node = require 'flow.classes.Node'
local processutils = require 'processutils'
local astro = require 'astro'
local verify = require 'verify'

local BasebandReady = objects.Class(Node)

function BasebandReady:init(seconds)
    local representation = astro.viz.Step {
        metadata = {
            name = 'Wait for Baseband Ready',
            description = 'Wait for Baseband Ready',
            results_name = 'BasebandReady'
        }
    }
    self.seconds = seconds or 20 -- default for the command line
    Node.init(self, representation)
end

function BasebandReady:run()
    local result
    verify.number(self.seconds)

    for i = 1, self.seconds do
        result = processutils.shell("/usr/local/bin/abmtool baseband state | grep BasebandBootStateIsReady")
        if result.code == 0 then
            break
        else
            print("Sleep 1 for iteration " .. i)
            processutils.shell('/bin/sleep 1')
        end
    end

    if result.code ==  0 then
        print("Result code is 0")
        self:save_pdca_records {
            {
                name = "BasebandReady",
                pass = true,
                message = "BasebandReady is ready"
            }
        }
        return
    else
        processutils.shell("abmtool baseband state")
        self:save_pdca_records {
            {
                name = "BasebandReady",
                pass = false,
                message = "BasebandReady not ready"
            }
        }
    end
end

return BasebandReady
