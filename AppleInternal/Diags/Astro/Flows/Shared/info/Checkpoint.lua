local Sequence = require "flow.Sequence"
local SaveTimestampCheckpoint = require "checkpoint.SaveTimestampCheckpoint"
local SaveSMCKeyCheckpoint = require "checkpoint.SaveSMCKeyCheckpoint"

local function Checkpoint(label)

    return Sequence {

        continue_on_fail = true,
        description = 'Checkpoint of timestamp, battery, and temperature',

        SaveTimestampCheckpoint {
            label = label,
        },

        SaveSMCKeyCheckpoint {
            label = label,
            B0AV = {units = "mV", description= "Battery pack voltage (mV)"},
            TP4d = {units = "C", description= "PMU tdev4 (C)"},
            TG0B = {units = "C", description= "GasGauge Battery (C)"},
        },
    }
end

return Checkpoint
