local DebugShell = require 'flowextensions.DebugShell'

return function()
    local pdca_path = '/private/var/logs/BurnIn/PDCA/_pdca_Sample_Value_Jump.plist'

    return DebugShell {
        name = 'Record HSCDTD602A Sample_Value_Jump events',
        description = 'Compass HSCDTD602A corrupt samples',
        results_name = 'HSCDTD602A_Sample_Value_Jump_events',
        command = '/usr/local/bin/OSDIOReportTool Count2 --channelName Sample_Value_Ju --testName Compass --subtestName IOReport --subsubtestName Sample_Value_Jump --units Events --pdcaPath ' .. pdca_path,
        pdca_plist_paths = {pdca_path}
    }
end
