#!/usr/bin/env python

import os, subprocess, tempfile, objc, sys, argparse

from ctypes import c_uint32, cdll, c_void_p, c_char_p
from subprocess import call, Popen, PIPE
from Foundation import NSData, NSDataWritingAtomic, NSDictionary

def _sh(cmd):
    proc = Popen(cmd, stdout=PIPE)
    return proc.stdout.read().strip()

_SDK_PLATFORM = os.environ.get('SDK_PLATFORM', 'iphoneos.internal')
_SDKROOT = os.environ.get('SDKROOT', _sh(['xcrun', '-sdk', _SDK_PLATFORM, '--show-sdk-path']))
assert _SDKROOT, 'Cannot find SDK {}'.format(_SDK_PLATFORM)
_IMG4PAYLOAD = _sh(['xcrun', '-sdk', _SDKROOT, '-find', 'img4payload'])
assert _IMG4PAYLOAD, 'Cannot find img4payload in {}'.format(_SDKROOT)
_IMG4UTILITY = _sh(['xcrun', '-sdk', _SDKROOT, '-find', 'img4utility'])
assert _IMG4UTILITY, 'Cannot find img4utility in {}'.format(_SDKROOT)

_libIOKit = cdll.LoadLibrary('/System/Library/Frameworks/IOKit.framework/IOKit')
_libIOKit.IOCFSerialize.argtypes = [ c_void_p, c_uint32 ]
_libIOKit.IOCFSerialize.restype = c_void_p
_libIOKit.IOCFUnserialize.argtypes = [ c_char_p, c_void_p, c_uint32, c_void_p ]
_libIOKit.IOCFUnserialize.restype = c_void_p

def unserialize(path):
    data = NSData.dataWithContentsOfFile_(path)
    assert data
    unserialized = _libIOKit.IOCFUnserialize(c_char_p(str(data)), None, 0, None)
    assert unserialized, 'Cannot unserialize. Invalid dictionary'
    return objc.objc_object(c_void_p=unserialized)

def serialize(image, path):
	serialized = _libIOKit.IOCFSerialize(objc.pyobjc_id(NSDictionary.dictionaryWithDictionary_(image)), 0)
	assert serialized, 'Cannot serialize. Invalid dictionary'
	data = objc.objc_object(c_void_p=serialized)
	succeeded, errorMessage = data.writeToFile_options_error_(path, NSDataWritingAtomic, None)
	assert succeeded, unicode(errorMessage)
    
def readImage(path):
    image = None
    fd, tmpPath = tempfile.mkstemp()
    try:
        exitCode = call([_IMG4UTILITY, '--copyBinary', '--input', path, '--output', tmpPath])
        assert exitCode == 0
        image = unserialize(tmpPath)
    finally:
        os.close(fd)
        os.remove(tmpPath)

    return image

def writeImage(image, path, tag, version):
    fd, tmpPath = tempfile.mkstemp()
    try:
        serialize(image, tmpPath)
    	exitCode = call([_IMG4PAYLOAD, '-t', tag,  '-v', str(version), '-i', tmpPath, '-o', path])
    	assert exitCode == 0
    finally:
        os.close(fd)
        os.remove(tmpPath)

def serializeFromPlist(args):
    plist = NSDictionary.dictionaryWithContentsOfFile_(args.source)
    serialize(plist, args.destination)

def unserializeToPlist(args):
    plist = unserialize(args.source)
    plist.writeToFile_atomically_(args.destination, True)

def readImageToPlist(args):
    plist = readImage(args.source)
    plist.writeToFile_atomically_(args.destination, True)

def writeImageFromPlist(args):
    plist = NSDictionary.dictionaryWithContentsOfFile_(args.source)
    writeImage(plist, args.destination, args.tag, args.version)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Python image4 converter")
    subparsers = parser.add_subparsers()
    #
    parser_read = subparsers.add_parser('read', help='Read im4p into plist')
    parser_read.add_argument('source', help='im4p source')
    parser_read.add_argument('destination', help='plist destination')
    parser_read.set_defaults(func=readImageToPlist)
    #
    parser_write = subparsers.add_parser('write', help='Write im4p to plist')
    parser_write.add_argument('source', help='plist source')
    parser_write.add_argument('destination', help='im4p destination')
    parser_write.add_argument('-t', '--tag', help='image4 tag', required=True)
    parser_write.add_argument('-v', '--version', type=int, help='image4 version', required=True)
    parser_write.set_defaults(func=writeImageFromPlist)
    #
    parser_serialize = subparsers.add_parser('serialize', help='Serialize plist into payload')
    parser_serialize.add_argument('source', help='plist source')
    parser_serialize.add_argument('destination', help='payload destination')
    parser_serialize.set_defaults(func=serializeFromPlist)
    #
    parser_serialize = subparsers.add_parser('unserialize', help='Unserialize payload to plist')
    parser_serialize.add_argument('source', help='payload source')
    parser_serialize.add_argument('destination', help='plist destination')
    parser_serialize.set_defaults(func=unserializeToPlist)
    #
    args = parser.parse_args()
    args.func(args)
