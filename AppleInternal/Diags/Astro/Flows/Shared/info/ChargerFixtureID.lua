local PowerTestShell = require 'classes.PowerTestShell'
local verify = require 'verify'
local Step = require 'flow.Step'
local Sequence = require 'flow.Sequence'
local flowconfig = require 'flowconfig'
local time = require 'time'
local If = require 'flow.If'
local Condition = require 'flow.classes.Condition'

--[[ <rdar://problem/48593390> BurnIn: Discover which chargers are causing retests
We want to record the charger serial number and/or cable serial number into PDCA/Insight.
The idea is that we can see which chargers are causing retests/failures. See the radar
for the logic around how HeadID and FixtureID are populated for different adapters.
For E75 / Lightning cables the cable serial number is available. For USB-C PD chargers
the charger serial number is available.

Typically you will not want to put this directly after WaitForCharger. That is because
USB-C chargers may pass WaitForCharger but may not yet have serial numbers loaded
into AdapterDetails. There needs to be some debounce time for this. I recommend
putting ChargerFixtureID about 10 seconds or later after WaitForCharger.

args is an optional table containing debounce_duration_seconds. If you do put
ChargerFixtureID after WaitForCharger then invoke it like:
ChargerFixtureID { debounce_duration_seconds = 10 }
--]]
return function(args)
    local debounce_duration_seconds = 0
    if args ~= nil and args.debounce_duration_seconds ~= nil then
        verify.number(args.debounce_duration_seconds)
        debounce_duration_seconds = args.debounce_duration_seconds
    end
    local pdca_path = '/var/logs/BurnIn/PDCA/_pdca_adapterdetails.plist'
    return Sequence {
        name = 'Record Charger/Cable to FixtureID',
        description = 'Records the cable and/or charger serial number to the FixtureID + HeadID fields',
        results_name = "ChargerFixtureID",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),
        --[[ Typically this sequence will be placed soon after WaitForAdapterDetails. However the AdapterDetails
             may be in flux and the USB charger may still not be fully enumerated. This is particularly a problem
             with USB-C PD (Power Delivery) chargers which transmits information over the USB-C CC wire. If we don't
             wait we may get an AdapterDetails match but then the charger serial number isn't present in the
             AdapterDetails. --]]
        If(Condition(debounce_duration_seconds > 0, "Debounce charger enumeration")) {
            Step {
                name = string.format('sleep %d', debounce_duration_seconds),
                description = "Wait for the charger to be fully enumerated",
                main = function(self)
                    time.sleep(debounce_duration_seconds)
                end
            },
        },
        -- AdapterDetails has logic to determine what serial numbers it should use to fill out HeadID / FixtureID
        PowerTestShell {
            name = 'Record AdapterDetails',
            command = '/usr/local/bin/OSDChargerTester AdapterDetails --setFixtureID=1 "--PDCAPath=' .. pdca_path .. '"',
            pdca_plist_paths = {pdca_path},
        }
    }
end
