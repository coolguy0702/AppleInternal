local Sequence = require 'flow.Sequence'
local DebugShell = require 'flowextensions.DebugShell'
local flowconfig = require 'flowconfig'
local BasebandReady = require 'utils.BasebandReady'
-- local Condition = require 'flow.classes.Condition'
-- local If = require 'flow.If'

return function()
    return Sequence {
        name = 'Set baseband to online mode',
        description = 'Set baseband flag to denote factory',
        results_name = "baseband_online_mode",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        on_enter = {
            BasebandReady(20)
        },

-- Keeping Eureka for the future
--        If(Condition("Karoo", function () return gFLOW_CONFIG.product_components[baseband.Karoo] end)){
                DebugShell {
                    name = "BB Online Mode",
                    command = '/usr/local/bin/KTLTool --nolibtu -v --timeoutMs=7500 bsp_set_nv_state 2',
                }
--            },
--        If(Condition("Eureka", function () return gFLOW_CONFIG.product_components[baseband.Eureka] end)){
--            Shell '/usr/local/bin/ETLTool -v ping',
--            Shell '/usr/local/bin/ETLTool -v nvwrite 453 0',
--            Shell '/usr/local/bin/ETLTool -v nvread 453'
--        }
    }
end
