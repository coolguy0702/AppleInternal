local classes = require 'classes'
local WithDisplayOn = require 'flowextensions.WithDisplayOn'

return function()
    return WithDisplayOn(classes.ComponentALS())
end
