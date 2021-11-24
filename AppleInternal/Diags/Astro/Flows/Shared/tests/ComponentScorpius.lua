local DebugShell = require 'flowextensions.DebugShell'
local Exception = require "exceptions.Exception"
-- Component test for Scorpius which performs a low power ping (object detect ping)
-- Supports three options for PDCAMode: recordNever, recordOnFailure, recordAlways
-- For an additional information read OSDComponent scorpius tool description

return function(pdca_mode)
    local pdca_path = nil
    local name = 'Component Scorpius'
    local results_name = 'ComponentScorpius'
    local timeout = 60

    if not pdca_mode then
        pdca_mode = "recordAlways"
    end

    if pdca_mode == "recordAlways" then
        pdca_path = '/private/var/logs/BurnIn/PDCA/osdcomponent_scorpius_record_always.plist'
    elseif pdca_mode == "recordOnFailure" then
        pdca_path = '/private/var/logs/BurnIn/PDCA/osdcomponent_scorpius_record_failure.plist'
    elseif pdca_mode == "recordNever" then
        pdca_path = nil
    else
        local msg = string.format('PDCAMode: %s is not supported by the tool', pdca_mode)
        error(Exception(msg))
    end

    name = name .. " " .. pdca_mode
    results_name = results_name .. "_" .. pdca_mode

    -- In OSDComponent scorpius setFirmwareStaticMode=1 by default.
    -- It is recommended to put Scorpius into “Static/Test” mode to do any factory test.
    -- It is worth checking if we need to put into this mode Scorpius for the next product
    if pdca_path then
        return DebugShell {
            name = name,
            results_name = results_name,
            command = string.format('/usr/local/bin/OSDComponent scorpius --PDCAMode=%s --PDCAPath=%s', pdca_mode, pdca_path),
            pdca_plist_paths = {pdca_path},
            timeout = timeout
        }
    else
        return DebugShell {
            name = name,
            results_name = results_name,
            command = string.format('/usr/local/bin/OSDComponent scorpius --PDCAMode=%s', pdca_mode),
            timeout = timeout
        }
    end
end
