-- <rdar://problem/48899749>
-- https://confluence.sd.apple.com/pages/viewpage.action?pageId=260035850
local PRTTShell = require 'classes.PRTTShell'
local Sequence = require 'flow.Sequence'
local flowconfig = require 'flowconfig'

local TCO_FILE_TO_AGGREGATE_PATH = '/private/var/logs/BurnIn/_tco_aggregate.plist'
local TCO_AGGREGATE_CHECK_PDCA_PATH = '/private/var/logs/BurnIn/PDCA/OSDPhosphorousAggregateCheckPDCA.plist'

local IMPORT_PRTT_PDCA_PATH = '/var/logs/BurnIn/PDCA/_pdca_ImportPRTT.plist'

local AGG_TCO_CHECK_PREDICATES = "'(TCO <= 0.0045 AND TemperatureDelta >= 8); (TCO >= 0.0045 AND TCO <= 0.005 AND MAD < 0.0025 AND TemperatureDelta >= 8)'"

return function()
    local motion_tester_cmd = '/usr/local/bin/OSDMotionTester'
    local import_prtt_cmd = motion_tester_cmd .. ' ImportPRTT' ..
                            ' --pdcaPath ' .. IMPORT_PRTT_PDCA_PATH ..
                            ' --aggregateOutputPath ' .. TCO_FILE_TO_AGGREGATE_PATH

    local agg_tco_check_cmd = motion_tester_cmd .. ' AggTcoCheck' ..
                              ' --aggType' .. ' predicate' ..
                              ' --filePath ' .. TCO_FILE_TO_AGGREGATE_PATH ..
                              ' --pdcaPath ' .. TCO_AGGREGATE_CHECK_PDCA_PATH ..
                              ' --predicates ' .. AGG_TCO_CHECK_PREDICATES

    return Sequence {
        name = "PRTT Write And Check Results",
        results_name = "PRTTWriteAndCheckResults",
        continue_on_fail = flowconfig.getglobal('continue_on_fail', true),

        PRTTShell {
            name = 'Import PRTT',
            results_name = 'ImportPRTT',
            command = import_prtt_cmd,
            timeout = 30,
            pdca_plist_paths = {IMPORT_PRTT_PDCA_PATH},
        },

        PRTTShell {
            name = 'Predicate based TCO check',
            results_name = 'PredicateBasedTCOcheck',
            command = agg_tco_check_cmd,
            timeout = 30,
            pdca_plist_paths = {TCO_AGGREGATE_CHECK_PDCA_PATH},
        },
    }
end
