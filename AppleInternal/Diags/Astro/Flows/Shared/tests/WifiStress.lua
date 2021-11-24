local classes = require 'classes'

return function(iteration_count, run_prepost_test, timeout, node)
    -- For running standalone
    if not iteration_count and not run_prepost_test and not timeout then
        iteration_count = 50
        run_prepost_test = false
        timeout = 30
    end

    return classes.WifiStress(iteration_count, run_prepost_test, timeout, node)
end
