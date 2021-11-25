import objc as _objc
import os as _os

def _loadFramework(frameworkName):
    frameworkIdentifier = "com.apple.{:s}".format(frameworkName)

    if '__XCODE_BUILT_PRODUCTS_DIR_PATHS' in _os.environ:
        frameworkDir = _os.environ['__XCODE_BUILT_PRODUCTS_DIR_PATHS']
    else:
        frameworkDir = "/AppleInternal/Library/Frameworks"

    frameworkPath = _os.path.join(frameworkDir, frameworkName + ".framework")

    return _objc.initFrameworkWrapper(frameworkName, frameworkIdentifier=frameworkIdentifier,
        frameworkPath=_objc.pathForFramework(frameworkPath), globals=globals())

__bundle__ = _loadFramework("AIDHIDSupport")

# enums need to be updated manually

class AIDHIDReportType:
    Feature = 0
    Input = 1
    Output = 2
    #legacy
    AIDHIDReportTypeFeature = 0
    AIDHIDReportTypeInput = 1
    AIDHIDReportTypeOutput = 2

# AIDTransport enums (updated maually)

class AIDTPowerState:
    Off = 0
    Sleep = 1
    On = 2

class AIDTImageOptions:
    Restore = 1 << 0
    LockChip = 1 << 3
    Reenumerate = 1 << 4

# Register selectors with blocks or out arguments
class _Group:
    @staticmethod
    def outArg(objc):
        return {"type_modifier": objc._C_OUT}
    #
    @staticmethod
    def blockArg(types, retval="v"):
        args = {}
        outPrefix = "_OUT_"
        for idx, t in enumerate(["^v"] + types):
            if t.startswith(outPrefix):
                args[idx] = {"type": t[len(outPrefix):], "type_modifier": objc._C_OUT}
            else:
                args[idx] = {"type": t}
        return {"type": "^@", "callable": {"arguments": args, "retval":{"type": retval}}}
    #
    @classmethod
    def blockArg_Void(cl, objc):
        return cl.blockArg([])
    #
    @classmethod
    def blockArg_Obj(cl, objc):
        return cl.blockArg(["@"])
    #
    @classmethod
    def blockArg_UInt8_Obj(cl, objc):
        return cl.blockArg(["C", "@"])
    #
    @classmethod
    def blockArg_Obj_Obj(cl, objc):
        return cl.blockArg(["@", "@"])
    #
    @classmethod
    def blockArg_UInt8_UInt8_Out(cl, objc):
        return cl.blockArg(["C", "C", "_OUT_^@"], "I")
    #
    @classmethod
    def blockArg_UInt8_UInt8_Obj(cl, objc):
        return cl.blockArg(["C", "C", "@"], "I")
    
    @staticmethod
    def registerGroups(objc, classes, groups):
        for group in groups:
            for claxx in classes:
                group.register(objc, claxx)
    #
    def __init__(self, selectors, args):
        self.selectors = selectors
        self.args = args
    #
    def register(self, objc, claxx):
        arguments = {}
        for idx, arg in enumerate(self.args):
            if arg == None:
                continue
            arguments[2 + idx] = arg(objc)
        for selector in self.selectors:
            objc.registerMetaDataForSelector(claxx, selector, {
                "arguments": arguments
            })

##################################################
# HID
##################################################

_Group.registerGroups(
    objc = _objc,
    classes = [
        b"AIDHIDDeviceBase",
    ],
    groups = [
        _Group([
                b"setInputReportAction:",
                b"setParsedReportAction:",
            ], [_Group.blockArg_UInt8_Obj]),
        _Group([
                b"setDeviceRemovedAction:",
            ], [_Group.blockArg_Void]),
        _Group([
                b"stop:",
                b"disableParser:",
                b"getDefaultParserType:",
                b"getRegistryProperties:",
            ], [_Group.outArg]), 
        _Group([
                b"getReport:error:",
                b"getReportParsed:error:",
                b"getReportByName:error:",
                b"startWithRunLoop:error:",
            ], [None, _Group.outArg]), 
        _Group([
                b"getReport:type:error:",
                b"getReportParsed:type:error:",
                b"getReportByName:type:error:",
                b"setReport:data:error:",
                b"setReportParsed:object:error:",
                b"setReportByName:object:error:",
                b"enableParser:config:error:",
            ], [None, None, _Group.outArg]), 
        _Group([
                b"setReport:type:data:error:",
                b"setReportParsed:type:data:error:",
                b"setReportByName:type:data:error:",
            ], [None, None, None, _Group.outArg]),
    ])

_Group.registerGroups(
    objc = _objc,
    classes = [
        b"AIDHIDUserDeviceLocal",
        b"AIDHIDUserDeviceRemote",
    ],
    groups = [
        _Group([
                b"setReadyAction:",
            ], [_Group.blockArg_Obj]), 
        _Group([
                b"setGetReportAction:",
            ], [_Group.blockArg_UInt8_UInt8_Out]),
        _Group([
                b"setSetReportAction:",
            ], [_Group.blockArg_UInt8_UInt8_Obj]),
        _Group([
                b"handleReport:data:error:",
            ], [None, None, _Group.outArg]), 
    ])

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"AIDHIDDeviceManagerLocal",
                b"AIDHIDDeviceManagerRemote",
            ],
      groups = [
        _Group([
                b"setDeviceAddedAction:",
            ], [_Group.blockArg_Obj]),
        _Group([
                b"allDevices:",
                b"stop:",
            ], [_Group.outArg]),
        _Group([
                b"devicesMatching:error:",
                b"startWithRunLoop:error:",
            ], [None, _Group.outArg]),
        _Group([
                b"createUserDevice:async:error:",
            ], [None, None, _Group.outArg]),
    ])

##################################################
# Ariadne
##################################################

_Group.registerGroups(
    objc = _objc,
    classes = [
        b"AIDAriadneDeviceLocal",
        b"AIDAriadneDeviceRemote",
    ],
    groups = [
        _Group([
                b"registerEvent:action:",
            ], [None, _Group.blockArg_Obj]),
        _Group([
                b"registerBeginEvent:endEvent:action:",
            ], [None, None, _Group.blockArg_Obj_Obj]),
        _Group([
                b"enableParser:config:action:error:",
            ], [None, None, _Group.blockArg_Obj, _Group.outArg]),
        _Group([
                b"stop:",
            ], [_Group.outArg]), 
        _Group([
                b"startWithRunLoop:error:",
            ], [None, _Group.outArg]), 
    ])

##################################################
# Logging
##################################################

_Group.registerGroups(
    objc = _objc,
    classes = [
                b"AIDLogDeviceLocal",
                b"AIDLogDeviceRemote",
    ],
    groups = [
        _Group([
                b"setLogAction:",
                b"setDeviceRemovedAction:",
            ], [_Group.blockArg_Obj]),
        _Group([
                b"stop:",
            ], [_Group.outArg]), 
        _Group([
                b"startWithRunLoop:error:",
            ], [None, _Group.outArg]), 
    ])

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"AIDLogManagerLocal",
                b"AIDLogManagerRemote",
            ],
      groups = [
        _Group([
                b"setLogEventAction:",
                b"setNewLogDeviceAction:",
            ], [_Group.blockArg_Obj]),
        _Group([
                b"stopStreaming:",
                b"stopMonitoring:",
            ], [_Group.outArg]),
        _Group([
                b"startStreamingWithRunLoop:error:",
            ], [None, _Group.outArg]),
        _Group([
                b"startMonitoringWithRunLoop:matchingArray:error:",
            ], [None, None, _Group.outArg]),
    ])

##################################################
# Transport
##################################################

_Group.registerGroups(
    objc = _objc,
    classes = [
                b"AIDTransportManagerLocal",
                b"AIDTransportManagerRemote",
    ],
    groups = [
        _Group([
                b"allDevices:",
            ], [_Group.outArg]), 
        _Group([
                b"deviceWithName:error:",
            ], [None, _Group.outArg]), 
    ])

_transportCommon = [
        _Group([
                b"reset:",
            ], [_Group.outArg]),
        _Group([
                b"setPower:error:",
            ], [None, _Group.outArg]),
        _Group([
                b"getPower:error:",
            ], [_Group.outArg, _Group.outArg]),
        _Group([
                b"loadImageFromPath:payloadOnly:options:error:",
            ], [None, None, None, _Group.outArg]),
    ]

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"AIDTransportCommonRemote",
            ],
      groups = _transportCommon
    )

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"AIDTransportDeviceLocal",
                b"AIDTransportDeviceRemote",
            ],
      groups = _transportCommon + [
        _Group([
                b"getInterfaces:",
                b"getReporterResults:",
                b"getMemoryDumpLevel:",
                b"clearMemoryDumps:",
            ], [_Group.outArg]), 
        _Group([
                b"getMemoryDumps:error:",
            ], [_Group.outArg, _Group.outArg]), 
        _Group([
                b"reloadProperties:error:",
                b"overridePersonality:error:",
                b"setMemoryDumpLevel:error:",
            ], [None, _Group.outArg]), 
        _Group([
                b"getProperty:value:error:",
            ], [None, _Group.outArg, _Group.outArg]), 
        _Group([
                b"updateProperty:value:options:error:",
            ], [None, None, None, _Group.outArg]), 
    ])

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"AIDTransportInterfaceLocal",
                b"AIDTransportInterfaceRemote",
            ],
      groups = _transportCommon + [
        _Group([
                b"setEnable:error:",
                b"getReport:error:",
            ], [None, _Group.outArg]), 
        _Group([
                b"setReport:data:error:",
            ], [None, None, _Group.outArg]), 
    ])
