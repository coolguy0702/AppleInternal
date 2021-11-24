local objects = require 'objects'
local Node = require 'flow.classes.Node'
local astro = require 'astro'
local processutils = require 'processutils'
local nfutils = require "nfutils"

local StockholmATE = objects.Class(Node)

function StockholmATE:init()
    local representation = astro.viz.Step {
        metadata = {
            name = 'Stockholm ATE',
            results_name = 'StockholmATE',
            description = 'Stockholm ATE'
        }
    }
    Node.init(self, representation)
end

function StockholmATE:run()
    local passed = true
    local result

    nfutils.unload_nf()

    for i = 0, 10, 1 do
        print('Stockholm ATE iteration ' .. i)
        result = processutils.shell('/usr/local/bin/nfrestore -p /private/var/logs/BurnIn/Scripts/ate_test_okemo.apdus', 30)
        if result.code ~= 0 then
            passed = false
        end
    end

    self:save_pdca_records {
        {
            name = "StockholmATE",
            pass = passed,
        }
    }
    nfutils.load_nf()

end

return StockholmATE
