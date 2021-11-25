#!/usr/bin/env python2.7

import sys
import re
from contextlib import contextmanager
from hierarchy import Hierarchy


class Units:
    Inches = 19
    Degrees = 20


class Pages:
    GenericDesktop = 1
    Simulation = 2
    VR = 3
    Sport = 4
    Game = 5
    GenericDevice = 6
    Keyboard = 7
    LEDs = 8
    Button = 9
    Ordinal = 0x0a
    Telephony = 0x0b
    Consumer = 0x0c
    Digitizer = 0x0d
    PhysicalInterfaceDevice = 0x0f
    Unicode = 0x10
    AlphanumericDisplay = 0x14
    MedicalInstrument = 0x40
    BarCodeScanner = 0x8c
    Scale = 0x8d
    MagneticStripReader = 0x8e
    Camera = 0x90
    Arcade = 0x91


class GenericDesktopPage:
    Pointer = 1
    Mouse = 2
    Joystick = 4
    GamePad = 5
    Keyboard = 6
    Keypad = 7
    MultiAxisController = 8
    TabletPCSystemControls = 9
    X = 0x30
    Y = 0x31
    Z = 0x32
    Rx = 0x33
    Ry = 0x34
    Rz = 0x35
    Slider = 0x36
    Dial = 0x37
    Wheel = 0x38
    HatSwitch = 0x39
    CountedBuffer = 0x3a
    ByteCount = 0x3b
    MotionWakeup = 0x3c
    Start = 0x3d
    Select = 0x3e
    Vx = 0x40
    Vy = 0x41
    Vz = 0x42
    Vbrx = 0x43
    Vbry = 0x44
    Vbrz = 0x45
    Vno = 0x46
    FeatureNotification = 0x47
    ResolutionMultiplier = 0x48
    SystemControl = 0x80
    SystemPowerDown = 0x81
    SystemSleep = 0x82
    SystemWakeUp = 0x83
    SystemContextMenu = 0x84
    # TODO ...

class Digitizer:
    Touchscreen = 0x04
    Stylus = 0x20

class Collections:
    Physical = 0
    Application = 1
    Logical = 2
    Report = 3
    NamedArray = 4
    UsageSwitch = 5
    UsageModifier = 6


def _namesForUsagePair(usagePage, usageID):
    pageName = None
    for n in [n for n in dir(Pages) if not n.startswith('_')]:
        if usagePage is getattr(Pages, n):
            pageName = n
            break
    if pageName is None:
        return (None, None)
    classForUsagePage = globals().get(pageName + 'Page')
    if classForUsagePage:
        for n in [n for n in dir(classForUsagePage) if not n.startswith('_')]:
            if usageID is getattr(classForUsagePage, n):
                return (pageName, n)
    return (pageName, None)


def _itemIteratorForFilePath(path):
    signedItemIDs = (0b000101, 0b001001, 0b001101, 0b010001)
    with open(sys.argv[1], 'rb') as f:
        binString = bytearray(f.read())
        itemID = None
        for byte in binString:
            if itemID is None:
                length = byte & 3
                itemID = byte >> 2
                if length is 3:
                    length = 4
                data = []
            else:
                data.append(byte)
            if length is 0:
                value = 0
                if len(data) is 0:
                    value = None
                else:
                    for d in reversed(data):
                        value <<= 8
                        value += d
                if itemID in signedItemIDs:
                    if value >= 2**(8 * len(data) - 1):
                        value -= 2**(8 * len(data))
                yield (itemID, value)
                itemID = None
            else:
                length -= 1


class HIDDescriptor:
    '''An easy way to generate valid HID descriptors.'''

    def __init__(self):
        self._data = bytearray()
        self._topLevelAppCollectionFound = False
        self._collectionLevel = 0
        self._classForUsagePage = None

        # global items
        self._reportSize = None
        self._reportCount = None
        self._logicalMinimum = None
        self._logicalMaximum = None
        self._usagePage = None

        # local items
        self._usage = None
        self._usageMinimum = None
        self._usageMaximum = None
        self._designatorIndex = None
        self._stringIndex = None
        self._stringMinimum = None
        self._stringMaximum = None
        self._delimiter = None

        self._hierarchy = Hierarchy('HID Descriptor')

    def parseDSLFile(self, path):
        with open(path, 'r') as f:
            cmd_splitter = re.compile(r'[(), ]')
            for line_num, line in enumerate(f, start=1):
                line = line.partition('#')[0].strip(' \t\n\r') # strip comments and whitespace
                if len(line) is 0:
                    continue
                command = [x for x in cmd_splitter.split(line) if len(x) > 0]
                if len(command) is 0:
                    continue
                if command[0] == 'UsagePage':
                    if len(command) is not 2:
                        raise(Exception('Syntax error on line {line_num} of {file_name}: {command} must have 1 argument'.format(line_num=line_num, file_name=f.name, command=command[0])))
                    if command[1] in dir(Pages):
                        self.usagePage(getattr(Pages, command[1]))
                    else:
                        pass
                        # TODO try to convert string to a uint16_t
                    continue

                if command[0] == 'Usage':
                    # TODO support an optional page parameter
                    if len(command) is not 2:
                        raise(Exception('Syntax error on line {0}'.format(line_num)))
                    if self._usagePage is None:
                        raise('Usage without a page parameter must be preceded by a UsagePage call.')

                    if self._classForUsagePage is None:
                        usageVal = int(command[1], 0)
                    else:
                        usageVal = getattr(self._classForUsagePage, command[1], None)

                    if usageVal is None:
                        usageVal = int(command[1], 0)
                    self.usage(usageVal)
                    continue

                print('{line_num} => {command}'.format(line_num=line_num, command=command))


    def parseBinaryFile(self, path):
        items = _itemIteratorForFilePath(path)
        for i in items:
            (itemID, value) = i
            if itemID is 1:
                self.usagePage(value)
            elif itemID is 2:
                self.usage(value)
            elif itemID is 5:
                self.logicalMinimum(value)
            elif itemID is 6:
                self.usageMinimum(value)
            elif itemID is 9:
                self.logicalMaximum(value)
            elif itemID is 0xa:
                self.usageMaximum(value)
            elif itemID is 0x1d:
                self.reportSize(value)
            elif itemID is 0x20:
                self.inputItem(value)
            elif itemID is 0x21:
                self.reportID(value)
            elif itemID is 0x25:
                self.reportCount(value)
            elif itemID is 40:
                self.beginCollection(value)
            elif itemID is 48:
                self.endCollection()
            else:
                raise Exception('Encountered an unrecognized short item: (0x%0x, %d)' % (itemID, value))

    @property
    def data(self):
        if not self._topLevelAppCollectionFound:
            raise Exception('No top-level application collection was found.')
        if self._collectionLevel is not 0:
            raise Exception('All beginCollection calls must have a corresponding endCollection call.')
        return self._data

    def prettyPrint(self):
        self._hierarchy.prettyPrint()

    @staticmethod
    def _encodeSignedValue(value):
        if value < -(2**31) or value >= 2**31:
            raise ValueError('%d is not representable as a signed 32-bit integer' % value)
        vals = (value & 0xff, (value >> 8) & 0xff, (value >> 16) & 0xff, (value >> 24) & 0xff)
        if value >= -(2**7) and value < 2**7:
            vals = vals[:1]
        elif value >= -(2**15) and value < 2**15:
            vals = vals[:2]
        return bytearray(vals)

    @staticmethod
    def _encodeUnsignedValue(value):
        if value < 0 or value >= 2**32:
            raise ValueError('%d is not representable as an unsigned 32-bit integer' % value)
        vals = (value & 0xff, (value >> 8) & 0xff, (value >> 16) & 0xff, (value >> 24) & 0xff)
        if value < 2**8:
            vals = vals[:1]
        elif value < 2**16:
            vals = vals[:2]
        return bytearray(vals)

    def _clearLocalItems(self):
        self._usage = None
        self._usageMinimum = None
        self._usageMaximum = None
        self._designatorIndex = None
        self._stringIndex = None
        self._stringMinimum = None
        self._stringMaximum = None
        self._delimiter = None

    def _shortItem(self, itemType, tag, value, signed):
        if signed:
            data = self._encodeSignedValue(value)
        else:
            data = self._encodeUnsignedValue(value)
        firstByte = len(data)
        if firstByte == 4:
            firstByte = 3
        # TODO validate itemType?
        firstByte |= itemType << 2
        firstByte |= tag << 4
        return bytearray((firstByte,)) + data

    def _globalItem(self, tag, value, signed=False):
        return self._shortItem(1, tag, value, signed)

    # all local items are unsigned
    def _localItem(self, tag, value):
        return self._shortItem(2, tag, value, signed=False)

    def usage(self, value, usageID=None):
        if usageID is not None:
            # interpret value as a page
            value <<= 16
            value += usageID
        if value > 0xffff:
            # this is both a usage ID and a usage page
            pageName, idName = _namesForUsagePair(value >> 16, value & 0xffff)
            if pageName:
                if idName:
                    name = pageName + '/' + idName
                else:
                    name = pageName + ('/0x%04x' % (value & 0xffff))
            else:
                name = '0x%04x/0x%04x' % (value >> 16, value & 0xffff)
        else:
            if self._usagePage is None:
                raise Exception('A usage ID must be paired with a usage page.')
            pageName, idName = _namesForUsagePair(self._usagePage, value)
            if idName is None:
                name = '0x%x' % value
            else:
                name = idName
        self._data += self._localItem(0, value)
        self._usage = value # TODO: make this a queue
        self._hierarchy.mkdir('Usage(%s)' % name)

    def usageMinimum(self, value):
        self._data += self._localItem(1, value)
        self._usage = value
        self._hierarchy.mkdir('UsageMinimum(0x%x)' % value)

    def usageMaximum(self, value):
        self._data += self._localItem(2, value)
        self._usage = value
        self._hierarchy.mkdir('UsageMaximum(0x%x)' % value)

    def usagePage(self, value):
        # TODO test type of value to accept both int and string
        name, _ = _namesForUsagePair(value, None)
        if name is None:
            name = '0x%04x' % value
        else:
            self._classForUsagePage = globals().get(name + 'Page')
        self._data += self._globalItem(0, value)
        self._usagePage = value
        self._hierarchy.mkdir('UsagePage(%s)' % name)

    def beginCollection(self, collectionType):
        name = None
        for c in [c for c in dir(Collections) if not c.startswith('_')]:
            if collectionType is getattr(Collections, c):
                name = c
                break
        if name is None:
            raise Exception('%u is not a valid collection type.' % collectionType)
        if self._collectionLevel is 0:
            if collectionType is 1:
                self._topLevelAppCollectionFound = True
            else:
                raise Exception('Top level collection must be an application collection.')
        if self._usage is None:
            raise Exception('Collections require a usage.')
        self._data += self._shortItem(itemType=0, tag=10, value=collectionType, signed=False)
        self._collectionLevel += 1
        self._clearLocalItems()
        self._hierarchy.mkdir('Collection(%s)' % name, True)

    def endCollection(self):
        if self._collectionLevel <= 0:
            raise Exception('Encountered an unmatched endCollection call.')
        self._data += bytearray((0xc0,))
        self._collectionLevel -= 1
        self._hierarchy.ascend()
        self._clearLocalItems()

    def reportID(self, value):
        self._data += self._globalItem(8, value)
        self._hierarchy.mkdir('ReportID(%u)' % value)

    def logicalMinimum(self, value):
        self._logicalMinimum = value
        self._data += self._globalItem(1, value=value, signed=True)
        self._hierarchy.mkdir('LogicalMinimum(%d)' % value)

    def logicalMaximum(self, value):
        self._logicalMaximum = value
        self._data += self._globalItem(2, value=value, signed=True)
        self._hierarchy.mkdir('LogicalMaximum(%d)' % value)

    def physicalMinimum(self, value):
        self._data += self._globalItem(3, value=value, signed=True)
        self._hierarchy.mkdir('PhysicalMinimum(%d)' % value)

    def physicalMaximum(self, value):
        self._data += self._globalItem(4, value=value, signed=True)
        self._hierarchy.mkdir('PhysicalMaximum(%d)' % value)

    def unitExponent(self, exponent):
        # note that exponents are encoded as a 4-bit signed integer
        if exponent < -8 or exponent > 7:
            raise ValueError('An exponent of %d is not within the allowed -8 to 7 range.' % exponent)
        if exponent < 0:
            value = 2**4 + exponent
        else:
            value = exponent
        # use signed=False because we've already done the encoding
        self._data += self._globalItem(5, value=value, signed=False)
        self._hierarchy.mkdir('UnitExponent(%d)' % exponent)

    # TODO: come up with an abstraction for this
    def unit(self, value):
        name = None
        for n in [n for n in dir(Units) if not n.startswith('_')]:
            if value is getattr(Units, n):
                name = n
                break
        if name is None:
            name = '0x%x' % value
        self._data += self._globalItem(6, value=value, signed=False)
        self._hierarchy.mkdir('Unit(%s)' % name)

    def dotsPerInch(self, dpi):
        if dpi <= 0:
            raise ValueError('DPI must be greater than 0.')
        if self._logicalMinimum is None or self._logicalMaximum is None:
            raise Exception('dotsPerInch requires logicalMinimum and logicalMaximum to be set.')
        if self._logicalMinimum >= self._logicalMaximum:
            raise ValueError('dotsPerInch requires logicalMinimum to be less than logicalMaximum.')
        if self._logicalMinimum + self._logicalMaximum is not 0:
            raise ValueError('dotsPerInch requires logicalMinimum + logicalMaximum to be equal.')

        # compute the smallest exponent possible, given that physicalMinimum
        # and physicalMaximum are signed 32-bit integers
        exp = -8
        while True:
            physicalMaximum = int(round((2.0 * self._logicalMaximum) / ((10.0**exp) * dpi) / 2))
            if physicalMaximum < 2**31:
                break
            exp += 1
            if exp > 7:
                raise ValueError('A DPI of %g cannot be expressed.')

        self.unit(Units.Inches)
        self.unitExponent(exp)
        self.physicalMinimum(-physicalMaximum)
        self.physicalMaximum(physicalMaximum)

    def reportSize(self, value):
        self._data += self._globalItem(7, value=value, signed=False)
        self._reportSize = value
        self._hierarchy.mkdir('ReportSize(%u)' % value)

    def reportCount(self, value):
        self._data += self._globalItem(9, value=value, signed=False)
        self._reportCount = value
        self._hierarchy.mkdir('ReportCount(%u)' % value)

    def inputItem(self, constant=False, variable=False, relative=False,
                  wrap=False, nonLinear=False, noPreferred=False,
                  nullState=False, bufferedBytes=False):
        if self._usage is None:
            if constant and self._reportSize and self._reportCount:
                # this is padding
                pass
            else:
                raise Exception('With the exception of padding, all main items require a usage.')
        value = constant
        value |= variable << 1
        value |= relative << 2
        value |= wrap << 3
        value |= nonLinear << 4
        value |= noPreferred << 5
        value |= nullState << 6
        value |= bufferedBytes << 8
        self._data += self._shortItem(itemType=0, tag=8, value=value, signed=False)
        self._clearLocalItems()
        self._hierarchy.mkdir('Input(%s)' % bin(value))


@contextmanager
def physicalCollection(desc):
    desc.beginCollection(Collections.Physical)
    yield desc
    desc.endCollection()


@contextmanager
def applicationCollection(desc):
    desc.beginCollection(Collections.Application)
    yield desc
    desc.endCollection()


@contextmanager
def logicalCollection(desc):
    desc.beginCollection(Collections.Logical)
    yield desc
    desc.endCollection()


@contextmanager
def reportCollection(desc):
    desc.beginCollection(Collections.Report)
    yield desc
    desc.endCollection()


@contextmanager
def namedArrayCollection(desc):
    desc.beginCollection(Collections.NamedArray)
    yield desc
    desc.endCollection()


@contextmanager
def usageSwitchCollection(desc):
    desc.beginCollection(Collections.UsageSwitch)
    yield desc
    desc.endCollection()


@contextmanager
def usageModifierCollection(desc):
    desc.beginCollection(Collections.UsageModifier)
    yield desc
    desc.endCollection()


if __name__ == '__main__':
    if len(sys.argv) is 2:
        desc = HIDDescriptor()
        desc.parseDSLFile(sys.argv[1])
        desc.prettyPrint()
        #sys.stdout.write(desc.data)
