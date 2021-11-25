local Step = require "flow.Step"
local verify = require "verify"
local display_management = require "display_management"

local function verify_display_integrity_behavior(display_integrity_behavior)
    verify.string(display_integrity_behavior.mode, "The mode must be a string! Not " .. type(display_integrity_behavior.mode))
    if display_integrity_behavior.mode ~= "pulse" then return end

    verify.table(display_integrity_behavior.pulse_settings, "The pulse_settings must be a table!, Not " .. type(display_integrity_behavior.pulse_settings))
    local pulse_settings = display_integrity_behavior.pulse_settings
    verify.number(pulse_settings.on_time_in_s, "The pulse_settings on_time_in_s must be a number! Not " .. type(pulse_settings.on_time_in_s))
    verify.number(pulse_settings.off_time_in_s, "The pulse_settings off_time_in_s must be a number! Not " .. type(pulse_settings.off_time_in_s))
    verify.string(pulse_settings.type, "The pulse_settings type must be a string! Not " .. type(pulse_settings.type))
end

-- Assumes the table has been verified
local function display_integrity_behavior_description(display_integrity_behavior)
    local string = "Update display integrity behavior: "
    if display_integrity_behavior.mode == "system" then
        string = string .. "system default"
    elseif display_integrity_behavior.mode == "pulse" then
        string = string .. string.format(
            "pulse %ss ON, %ss %s",
            display_integrity_behavior.pulse_settings.on_time_in_s,
            display_integrity_behavior.pulse_settings.off_time_in_s,
            display_integrity_behavior.pulse_settings.type == "power" and "OFF" or "BLACK"
        )
    else
        string = string .. "unknown"
    end

    return string
end

return function(display_integrity_behavior)
--  {
--      mode = "system/pulse",
--      pulse_settings = {
--          on_time_in_s = #,
--          off_time_in_s = #,
--          type = "power/blank",
--  }
    verify_display_integrity_behavior(display_integrity_behavior)

    return Step {
        name = "Update display integrity behavior",
        results_name = "UpdateDisplayIntegrityBehavior",
        description = display_integrity_behavior_description(display_integrity_behavior),

        main = function(self)
            display_management.update_display_inactivity_settings(display_integrity_behavior)
        end
    }
end
