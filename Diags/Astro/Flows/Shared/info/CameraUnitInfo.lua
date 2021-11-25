local DebugShell = require "flowextensions.DebugShell"

return function()
    return DebugShell {
        name = "Save ISP Unit Info to plist",
        -- ISP script is called which will pushd into the folder which produces ISPUnitInfo.plist by the ISP script
        command = "pushd $ASTRO_WORKING_DIRECTORY; /usr/local/bin/h10isp -n -s /var/logs/BurnIn/Scripts/Resources/dumpIspUnitInfo_script.txt 2&>1 /dev/null; popd",
        timeout = 30
    }
end
