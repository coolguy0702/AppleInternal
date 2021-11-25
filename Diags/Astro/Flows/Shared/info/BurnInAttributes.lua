local Sequence = require 'flow.Sequence'
local Step = require 'flow.Step'
local osd_root = require 'versions.osd_root'
local lld_root = require 'versions.lld_root'
local bootargs = require 'bootargs'
local sysconfig = require 'sysconfig'
local epcall = require 'exceptions.epcall'

return function()
    return Sequence {
        continue_on_fail = true,

            Step('Save BurnIn versions', function (self)
                -- if CFG# is missing that is okay
                -- if the epcall fails cfg will be the exception back trace
                -- so we should just set cfg to "" on error
                local success, cfg = epcall(sysconfig.read, 'CFG#')
                if not success then cfg = "" end

                self:save_software_attributes {
                    osd_root_version = osd_root(),
                    lld_root_version = lld_root(),
                    cfg = cfg,
                    bootargs = bootargs.all(),
                }
            end)
    }
end
