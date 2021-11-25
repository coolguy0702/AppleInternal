local DebugShell = require 'flowextensions.DebugShell'

return function()
    local pdca_file = '_pdca_osdnandtester_history.plist'
    local pdca_dir = '$ASTRO_NODE_LOG_DIRECTORY'
    local pdca_path = pdca_dir .. '/' .. pdca_file
    return DebugShell {
        name = 'RxBurn History',
        description = "Record RxBurn historical data",
        results_name = "RxBurnHistory",
        command = string.format('/bin/mkdir -p "%s"; /usr/local/bin/OSDNANDTester history --pdca="%s"', pdca_dir, pdca_path),
        pdca_plist_paths = {pdca_path}
    }
end
