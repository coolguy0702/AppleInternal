-- <rdar://problem/48899749>
-- https://confluence.sd.apple.com/pages/viewpage.action?pageId=260035850
local classes = require 'classes'

return function(args)
    if args == nil then
        -- set default args
        args = {prttTag = 'defaultPRTTTag',
                duration = 300}
    end

    return classes.PRTTHeating(args)
end
