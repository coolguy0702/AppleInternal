-- TODO: Test Documentation
-- Juliet SYNC test: the pearl streaming mode is the front RGB + front IR syncronized with the RGB acting has HW sync master (driving capture on the IR)
local ISPFWLogShell = require 'flowextensions.ISPFWLogShell'
local Sequence = require 'flow.Sequence'
local RxBurnPause = require 'tests.rxburn.Pause'
local RxBurnResume = require 'tests.rxburn.Resume'

return function()
    return Sequence {
        on_enter = {
            RxBurnPause()
        },
        description = "Pearl SYNC with RxBurn disabled",

        ISPFWLogShell {
            name = 'Pearl SYNC',
            command = '/usr/local/bin/OSDCameraTester SyncStreamSanity --group pearl --primaryFormatIndex 1 --secondaryFormatIndex 0 --frameRate 30 --frames 20 --framesToWait 10'
        },

        on_exit = {
            RxBurnResume()
        }
    }
end
