local Shell = require 'flow.Shell'

return function()
    return Shell {
        name = 'Gyro Angular Deviation',
        command = '/usr/local/bin/OSDMotionTester GyroAngularDeviation -o 800 -w 0 -r 50',
        pdca_plist_paths = {'/var/logs/BurnIn/PDCA/OSDGyroAngularDeviationPDCA.plist'}
    }
end
