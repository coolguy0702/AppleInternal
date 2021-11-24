import objc as _objc
import os as _os
from Foundation import NSDictionary

_frameworkName = "MultitouchStreaming"

if '__XCODE_BUILT_PRODUCTS_DIR_PATHS' in _os.environ:
    _frameworkDir = _os.environ['__XCODE_BUILT_PRODUCTS_DIR_PATHS']
else:
    _frameworkDir = "/AppleInternal/Library/Frameworks"

_frameworkPath = _os.path.join(_frameworkDir, _frameworkName + ".framework")

__bundle__ = _objc.initFrameworkWrapper(_frameworkName,
                                        frameworkIdentifier=("com.apple." + _frameworkName),
                                        frameworkPath=_objc.pathForFramework(_frameworkPath),
                                        globals=globals())

# We need to manually update this enums because they are only available at compilation time

class MTTouchRangeStage:
    NotTracking     = 0
    StartInRange    = 1
    HoverInRange    = 2
    MakeTouch       = 3
    Touching        = 4
    BreakTouch      = 5
    LingerInRange   = 6
    OutOfRange      = 7

class MTContactIdentity:
    Unknown = 0
    Null = 0
    Thumb = 1
    IndexFinger = 2
    MiddleFinger = 3
    RingFinger = 4
    PinkyFinger = 5
    Cheek = 6
    OuterPalmHeel = 6
    Chin = 7
    InnerPalmHeel = 7
    FireflyTip = 7
    Ear0 = 8
    PalmSatellite = 8
    ForePalm0 = 8
    Ear1 = 9
    Knuckle = 9
    ForePalm1 = 9
    Ear2 = 10
    WeakSpuriousTouch = 10
    ForePalm2 = 10
    Ear3 = 11
    ProxCheekEar = 11
    ForceCentroid = 11
    FireflyTilt = 11
    ForePalm3 = 11
    EdgeStraddle0 = 12
    EdgeStraddle1 = 13
    CornerPalm = 13
    ThumbAlongEdge = 14
    HandCenter = 15
    MaxPerHand = 16
    NonExtendedMask = 0xF

class MTPathFlags:
    FromEdge                = 0x1
    EdgeSwipePending        = 0x2
    EdgeSwipeLocked         = 0x4
    SwipeLocked             = 0x10
    SwipePending            = 0x20
    EdgePressPending        = 0x40
    EdgePressActive         = 0x80
    EdgeSwipeOriginLeft     = 0x100
    EdgeSwipeOriginRight    = 0x200
    EdgeSwipeOriginTop      = 0x400
    EdgeSwipeOriginBottom   = 0x800
    isFireflyPath           = 0x1000
    isStylusPath            = 0x1000
    EstimatedFireflyAngle   = 0x2000

class MTHandIdentity:
    LeftHand    = -1
    UnknownHand = 0
    RightHand   = 1

class MTFrameContent:
    Header      = (1 << 0)
    Paths       = (1 << 1)
    Image       = (1 << 2) # deprecated
    Images      = (1 << 2)
    Bytes       = (1 << 3)
    Translation = (1 << 4)

class MTImageRegionMask:
    Unknown        = (1 <<  0)
    Multitouch     = (1 <<  1)
    Force          = (1 <<  2)
    Optical        = (1 <<  3)
    CommonMode     = (1 <<  8)
    NoiseSPA       = (1 <<  9)
    StylusX        = (1 << 12)
    StylusY        = (1 << 13)
    OrbCore        = (1 << 16)
    OrbCrashpad    = (1 << 18)
    AllDevice      = 0x7FFFFFFE
    AllDeviceDeprecated = 0xFE

class MTNotificationEvent:
    DeviceBootloaded = 1
    TimestampsOutOfOrder = 2
    DeviceUILocked = 3
    DeviceUIUnlocked = 4
    DeviceReady = 5
    DeviceKilled = 6
    DevicePoweredOn = 7
    DevicePoweredOff = 8
    DetectionModeStandard = 9
    DetectionModeFaceExpected = 10
    DetectionModeCustom = 11
    UserPreferencesChanged = 12
    DisablerChanged = 13
    DeviceSuspended = 14
    DeviceResumed = 15
    ButtonPressed = 16
    ButtonReleased = 17
    SurfaceOriented0Degrees = 18
    SurfaceOriented180Degrees = 19
    DetectionModeFacePresent = 20
    DetectionModeFaceMonitoring = 21
    DetectionModeFaceExpectedFromMonitoring = 22
    DetectionModeLocked = 23
    DetectionModePocketTouchesExpected = 24
    DetectionModePocketTouchesExpectedAndFaceMonitoring = 25
    ParserEnabledStateChanged = 26
    SystemActuationsChanged = 27
    SystemForceResponseChanged = 28
    HostClickControlEnabled = 29
    HostClickControlDisabled = 30
    DetectionModeLockedWithWakeDetection = 31
    DeviceWillPowerOn = 32
    FilteredClientsAvailable = 33
    FilteredClientsUnavailable = 34
    PrivOffset = 100    
    Z2BridgeStatusOffset = 300 
    BridgeStatusReset = 301
    BridgeStatusInitDone = 302
    BridgeStatusWakeFromSleep = 303
    BridgeStatusGoodByeWorld = 304
    BridgeStatusWDTFired = 305
    BridgeStatusExtOrSWResetInitDone = 316
    BridgeStatusPowerOnResetInitDone = 317
    BridgeStatusWDGResetInitDone = 318
    BridgeStatusWakeOnTouch = 332

# See MultitouchStreaming/MTRecording.h for documentation
class MTRecordingKey:
    DeviceInfo = "DeviceInfo"
    RegistryProperties = "RegistryProperties"
    Frames = "Frames"
    CaptureBeginTimestamp = "CaptureBeginTimestamp"
    DeviceIndex = "DeviceIndex"
    MTFrame = "MTFrame"
    HostTimestamp = "HostTimestamp"
    Annotation =  "Annotation"
    DevicesRecorded = "DevicesRecorded"
    DevicesInfo = "DevicesInfo"
    DevicesRegistryProperties = "DevicesRegistryProperties"

class MTPlayerState:
    Stopped = 0
    Paused = 1
    Playing = 2

# Register selectors with blocks or out arguments
class _Group:
    blockObjArg = {
        "type": "^@", "callable": {
            "arguments": {
                0: {"type": "^v"},
                1: {"type": "@"}
            }
        }
    }
    
    blockObjArgRetInt = {
        "type": "^@", "callable": {
            "arguments": {
                0: {"type": "^v"},
                1: {"type": "@"}
            },
            "retval": {
                "type": "I",
            }
        }
    }
    
    blockIntArg = {
        "type": "^@", "callable": {
            "arguments": {
                0: {"type": "^v"},
                1: {"type": "i"}
            }
        }
    }
    
    blockIntOutArg = {
        "type": "^@", "callable": {
            "arguments": {
                0: {"type": "^v"},
                1: {"type": "C"},
                2: {"type": "^@", "type_modifier": _objc._C_OUT},
            },
            "retval": {
                "type": "I",
            }
        }
    }
    
    blockIntObjArg = {
        "type": "^@", "callable": {
            "arguments": {
                0: {"type": "^v"},
                1: {"type": "C"},
                2: {"type": "@"},
            },
            "retval": {
                "type": "I",
            }
        }
    }
    
    blockVoidArg = {
        "type": "^@", "callable": {
            "arguments": {
                0: {"type": "^v"}
            }
        }
    }

    outArg = {                        
        "type_modifier": _objc._C_OUT
    }

    @staticmethod
    def registerGroups(objc, classes, groups):
        for group in groups:
            for claxx in classes:
                group.register(objc, claxx)

    def __init__(self, selectors, args):
        self.selectors = selectors
        self.args = args

    def register(self, objc, claxx):
        arguments = {}
        for idx, arg in enumerate(self.args):
            if arg == None:
                continue
            arguments[2 + idx] = arg
        for selector in self.selectors:
            objc.registerMetaDataForSelector(claxx, selector, {
                "arguments": arguments
            })

_Group.registerGroups(
    objc = _objc,
    classes = [
        b"MTDeviceBase",
    ],
    groups = [
        _Group([
                b"setFrameAction:",
            ], [_Group.blockObjArg]),
        _Group([
                b"setNotificationAction:",
            ], [_Group.blockIntArg]),
        _Group([
                b"setDeviceRemovedAction:",
            ], [_Group.blockVoidArg]),
        _Group([
                b"registerPathCallback:handler:",
                b"registerImageCallback:handler:",
                b"registerFrameHeaderCallback:handler:",
            ], [_Group.outArg, _Group.blockObjArg]),
        _Group([
                b"stop:",
                b"unregisterPathCallback:",
                b"unregisterImageCallback:",
                b"unregisterFrameHeaderCallback:",
                b"getRegistryProperties:",
            ], [_Group.outArg]), 
        _Group([
                b"startWithRunLoop:error:",
                b"startFilterWithRunLoop:error:",
                b"getReport:error:",
                b"injectFrame:error:",
            ], [None, _Group.outArg]), 
        _Group([
                b"startWithOptions:runLoop:error:",
                b"setReport:data:error:",
            ], [None, None, _Group.outArg]), 
        _Group([
                b"injectFrameWithHeader:paths:image:error:",
            ], [None, None, None, _Group.outArg]),
    ])

_Group.registerGroups(
    objc = _objc,
    classes = [
        b"MTUserDeviceLocal",
        b"MTUserDeviceRemote",
    ],
    groups = [
        _Group([
                b"setReadyAction:",
            ], [_Group.blockObjArg]), 
        _Group([
                b"setGetReportAction:",
            ], [_Group.blockIntOutArg]),
        _Group([
                b"setSetReportAction:",
            ], [_Group.blockIntObjArg]),
    ])

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"MTDeviceManagerLocal",
                b"MTDeviceManagerRemote",
            ],
      groups = [
        _Group([
                b"setDeviceAddedAction:",
            ], [_Group.blockObjArg]),
        _Group([
                b"allDevices:",
                b"stop:",
            ], [_Group.outArg]),
        _Group([
                b"startWithRunLoop:error:",
                b"devicesMatching:error:",
            ], [None, _Group.outArg]),
        _Group([
                b"createUserDevice:async:error:",
            ], [None, None, _Group.outArg]),
    ])

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"MTRecording",
            ],
      groups = [
        _Group([
                b"parseData:error:",
                b"parseFile:error:",
            ], [None, _Group.outArg]),
    ])

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"MTRecordingWriter",
            ],
      groups = [
        _Group([
                b"flush:",
                b"close:",
            ], [_Group.outArg]),
        _Group([
                b"initToFileAtPath:error:",
                b"initToLegacyFileAtPath:error:",
                b"openWithFile:error:",
                b"openWithDictionary:error:",
            ], [None, _Group.outArg]),
        _Group([
                b"convertRecordingFromFile:toLegacyFile:error:",
                b"openWithRegistryProperties:startTimestamp:error:",
            ], [None, None, _Group.outArg]),
        _Group([
                b"convertRecordingFromFile:toFile:flushInterval:error:",
                b"openWithDevice:startTimestamp:metadata:error:",
                b"openWithDevices:startTimestamp:metadata:error:",
                b"addFrame:sinceStart:metadata:error:",
                b"addFrameBytes:sinceStart:length:error:",
                b"addAnnotationBytes:sinceStart:length:error:",
            ], [None, None, None, _Group.outArg]),
        _Group([
                b"addFrame:sinceStart:deviceIndex:metadata:error:",
            ], [None, None, None, None, _Group.outArg]),
    ])

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"MTPlayer",
            ],
      groups = [
        _Group([
                b"setFrameAction:",
            ], [_Group.blockObjArgRetInt]),
        _Group([
                b"setStateAction:",
            ], [_Group.blockIntArg]),
        _Group([
                b"stop:",
                b"pause:",
            ], [_Group.outArg]),
        _Group([
                b"initWithDictionary:error:",
                b"startWithRunLoop:error:",
                b"startWithDispatchQueue:error:",
            ], [None, _Group.outArg]),
    ])

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"MTDevicePlayer",
            ],
      groups = [
        _Group([
                b"setStateAction:",
            ], [_Group.blockIntArg]),
        _Group([
                b"start:",
                b"stop:",
                b"pause:",
            ], [_Group.outArg]),
        _Group([
                b"initWithFile:error:",
                b"initWithDictionary:error:",
                b"startWithRunLoop:error:",
                b"startWithDispatchQueue:error:",
            ], [None, _Group.outArg]),
        _Group([
                b"initWithFile:devices:error:",
                b"initWithDictionary:devices:error:",
            ], [None, None, _Group.outArg]),
        _Group([
                b"initWithFile:injectionTimeoutMs:noParser:manager:error:",
                b"initWithDictionary:injectionTimeoutMs:noParser:manager:error:",
            ], [None, None, None, None, _Group.outArg]),
    ])

_Group.registerGroups(
      objc = _objc,
      classes = [
                b"MTDeviceRecorder",
            ],
      groups = [
        _Group([
                b"open:",
                b"close:",
            ], [_Group.outArg]),
        _Group([
                b"openWithRunLoop:error:",
                b"openWithDispatchQueue:error:",
            ], [None, _Group.outArg]),
        _Group([
                b"initToLegacyFileAtPath:devices:error:",
            ], [None, None, _Group.outArg]),
        _Group([
                b"initToFileAtPath:flushInterval:devices:error:",
            ], [None, None, None, _Group.outArg]),
    ])

