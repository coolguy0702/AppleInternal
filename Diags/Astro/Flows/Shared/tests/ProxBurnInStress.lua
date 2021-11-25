local ProxTestShell = require 'classes.ProxTestShell'

return function()
    return ProxTestShell {
        name = "Prox VCSEL BI Stress",
        command = "/usr/local/bin/OSDProxTester -t 0 --active YES",
        timeout = 30,
    }
end
