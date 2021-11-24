local objects = require 'objects'
local Node = require 'flow.classes.Node'
local astro = require 'astro'
local time = require 'time'
local epcall = require 'exceptions.epcall'
local ioaccessory = require 'ioaccessory'
local iopowersource = require 'iopowersource'

local WaitForAdapterDetails = objects.Class(Node)

function WaitForAdapterDetails:init(brick_name, ...)
    local representation = astro.viz.Step {
        metadata = {
            name = 'Wait for ' .. brick_name,
            description = 'Wait for ' .. brick_name,
            results_name = brick_name
        }
    }

    self.adapter_details = {...}
    Node.init(self, representation)
end

function WaitForAdapterDetails:check_for_charger()
    -- If table of tables
    local match
    local success, e = epcall(function()
        match = iopowersource.adapter_details_matching(table.unpack(self.adapter_details))
    end)

    -- Could optionally print the match here

    return match
end

function WaitForAdapterDetails:run()
--        | |   |       |       |   "AdapterDetails" = {"SharedSource"=0,"Amperage"=1000,"AdapterVoltage"=5000,"FamilyCode"=18446744073172697091,"SourceID"=0,"Watts"=5,"PMUConfiguration"=1000,"Description"="usb brick"}

    local finished = false
    if self:check_for_charger() then -- If adapter already plugged in, no need to check
        return
    end

    while true do
        if finished then
            break
        end
        print('Waiting for accessory notification')
        ioaccessory.wait_for_accessory_notification()

        -- Poll a few times at a 1s interval. Seeing HVC Menu index populated in about 30s, so giving extra time
        for _ = 0, 60, 1 do
            if self:check_for_charger() then
                print('Found a matching charger')
                finished = true
                break
            end
            time.sleep(1)
        end

        if not finished then
            print('Did not match after accessory notification, waiting for another notification')
        end
    end
end

return WaitForAdapterDetails

-- TODO we need a backdoor in case chargers not available
