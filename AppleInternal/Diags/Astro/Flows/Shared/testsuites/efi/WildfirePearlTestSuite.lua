local smokey = require "smokey"
local Smokey = smokey.Smokey

return function (iterations)
    local test_iterations = iterations or 1

    return Smokey {
        sequence = "Wildfire",
        brick_required = smokey.types.Brick.NONE,
        tests = {
            {
                name = "PearlTestSuite",
                iterations = test_iterations,
            },
        }
    }
end
