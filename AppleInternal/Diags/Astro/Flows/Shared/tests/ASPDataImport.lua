local Shell = require 'flow.Shell'

-- Note: This test MUST be placed after Bonfire or RxBurn is finished. Otherwise,
-- we will collect data from incomplete NAND testing.
-- <rdar://problem/28392092> [master] Earthbound add comment for future ignore of ASPTool
-- If ASPTool fails due to a non-zero status code at MP then this ignore can be set to YES
-- Note that this should _not_ be ignored during engineering builds
-- Note that if a failure occurs due to a missing PDCA.plist below then Noam Shmueli and Matt Byom should be contacted for a fix
return function()
    return Shell {
        name = "ASPDataImport",
        description = "Import AppleStorageProcessor (ASP) PTS and BBT data",

        -- ASPTool will not create any subdirectories on its own because it's using -[NSDictionary writeToFile:atomically:]
        command = "mkdir -p $ASTRO_NODE_LOG_DIRECTORY; /usr/local/bin/ASPTool -P $ASTRO_NODE_LOG_DIRECTORY",

        -- From Earthbound
        timeout = 60,

        pdca_plist_paths = {
            -- These names are defined by ASPTool
            '$ASTRO_NODE_LOG_DIRECTORY/_pdca_pts_data.plist',
            '$ASTRO_NODE_LOG_DIRECTORY/_pdca_bbt_data.plist',
        },
    }
end
