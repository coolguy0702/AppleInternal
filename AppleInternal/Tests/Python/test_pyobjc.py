#!/usr/bin/env python3

import sys
import sysconfig

if sysconfig.get_config_var('TARGET_OS_EMBEDDED'):
    sys.exit(69) # skip test

import Foundation

def read_plist(data):
    if isinstance(data, Foundation.NSData):
        nsdata = data
    else:
        nsdata = Foundation.NSMutableData.dataWithBytes_length_(data, len(data))
    plist, fmt, error =  Foundation.NSPropertyListSerialization.propertyListWithData_options_format_error_(
        nsdata, Foundation.NSPropertyListImmutable, None, None)
    if error:
        raise Exception("error reading plist " + str(error))
    return plist

plist = read_plist(bytes.fromhex("""
62 70 6c 69 73 74 30 30 d1 01 02 57 6d 65 73 73
61 67 65 5d 48 65 6c 6c 6f 2c 20 77 6f 72 6c 64
21 08 0b 13 00 00 00 00 00 00 01 01 00 00 00 00
00 00 00 03 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 21                                    
"""))

if plist['message'] != 'Hello, world!':
    raise Exception

print("passed")

sys.exit(0)



