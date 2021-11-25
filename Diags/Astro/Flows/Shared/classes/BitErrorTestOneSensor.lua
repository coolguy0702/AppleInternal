local verify = require "verify"
local objects = require 'objects'
local ISPFWLogShell = require 'flowextensions.ISPFWLogShell'
local BitErrorTestOneSensor = objects.Class(ISPFWLogShell)

-- This function takes: camera, time, width, height, fps, linkHz, with_pattern, camera_label, timeout
function BitErrorTestOneSensor:init(args)

    verify.table(args)
    verify.string(args.camera)
    verify.number(args.time)
    verify.number(args.width)
    verify.number(args.height)
    verify.number(args.fps)
    verify.boolean(args.with_pattern)
    verify.string(args.camera_label)
    verify.number(args.timeout)

    local command = "/usr/local/bin/OSDCameraTester BitErrorTestOneSensor"
    command = command .. string.format(" --camera=%s --time=%s --width=%s --height=%s --fps=%s", args.camera, args.time, args.width, args.height, args.fps)

    if args.linkHz then
        command = command .. " --linkHz=" .. args.linkHz
    end

    local label = args.camera_label

    if args.with_pattern then
        command = command .. " --pattern=5"
        label = label .. "WithPattern"
    end

    local name = string.format("BitErrorTestOneSensor %s", label)
    local results_name = string.format("BitErrorTestOneSensor%s", label)
    local pdca_path = "/private/var/logs/BurnIn/PDCA/"
    command = command .. string.format(" --label=%s", label)
    pdca_path = pdca_path .. string.format("_pdca_BitErrorTest_%s.plist", label)

    ISPFWLogShell.init(self, {
        name = name,
        results_name = results_name,
        command = command,
        timeout = args.timeout,
        pdca_plist_paths = {pdca_path}
    })

end

return BitErrorTestOneSensor
