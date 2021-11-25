#!/usr/bin/env python
# -*-Python-*-
################################################################################
#
# Copyright (C) 2016  Apple, Inc. All rights reserved.
#
# This document is the property of Apple Inc.
# It is considered confidential and proprietary.
#
# This document may not be reproduced or transmitted in any form,
# in whole or in part, without the express written permission of
# Apple Inc.
#
################################################################################
# Summary: Python routines to generate Macho format binaries
# Version: 0.1
# Author: Jesse Rosenberg
################################################################################
import sys
import os
import argparse
import pdb
import base64
from struct import *
from pprint import pprint

class MachoHeader:
    def __init__(self):
        self.magic = 0xFEEDFACE
        self.cpu = 12
        self.sub_cpu = 16
        #MH_
        self.type = 2
        self.ncmd = 0
        self.sizeofcmds = 0
        self.flags  = 0
        self.size = 28
    
    def output(self):
        pprint (vars(self))
    
    def serialization(self):
        #Pack using standard size
        p = pack('=LLLLLLL',
                 self.magic,
                 self.cpu,
                 self.sub_cpu,
                 self.type,
                 self.ncmd,
                 self.sizeofcmds,
                 self.flags)
        return p

#Object to be added to a list in an HBPP Load Command
class HBPPOperation:
    def __init__(self, parent, opcode, address, bitmask=0, compare=0, delay=0, final=None):
        if not isinstance(parent, HBPPCommand):
            sys.exit("Error - Unsupported data type")
        self.opcode = opcode;
        self.address = address;
        self.bitmask = bitmask;
        self.compare = compare;
        self.delay = delay;
        if self.opcode is None or self.address is None:
            sys.exit("Error - Opcode and address are requried")
        parent.insertHBPP(self, final)

    def output(self):
        pprint (vars(self))
    
    def serialization(self):
        p = pack('=LLLLL',
                 self.opcode,
                 self.address,
                 self.bitmask,
                 self.compare,
                 self.delay )
        return p
        
class PollDataCommand:
    def __init__(self, pollAddr, parent):
        assert( isinstance(parent, MachoFile) )
        assert (isinstance(pollAddr, int))
        self.cmd = 0x8685
        self.cmdsize = 12
        self.addr = pollAddr
        self.parent = parent
        self.parent.insertCmd(self)

    def serialization(self):
        p = []
        p.append(pack('=LLL',
                      self.cmd,
                      self.cmdsize,
                      self.addr))
        return "".join(p)

    def output(self):
        pprint(vars(self))

class HBPPCommand:
    def __init__(self, parent):
        if not isinstance(parent, MachoFile):
            sys.exit("Error - Unsupported data type")
        self.cmd = 0x8686
        self.cmdsize = 12
        self.hbpp_list = []
        self.parent = parent
    
    def insertHBPP(self, hbpp, final):
        if not isinstance(hbpp, HBPPOperation):
            sys.exit("Error - Unsupported data type")
        self.hbpp_list.append(hbpp)
        self.cmdsize+=20;
        #Insert into parent struct when list is completed
        if final is not None:
            self.parent.insertCmd(self)

    def commit(self):
        self.parent.insertCmd(self)

    def serialization(self):
        p = []
        p.append( pack('=LLL',
                       self.cmd,
                       self.cmdsize,
                       len(self.hbpp_list) ) )
        for h in self.hbpp_list:
            p.append( h.serialization() )
        return "".join(p)

    def output(self):
        pprint (vars(self))
        for h in self.hbpp_list:
            h.output()

class FakeCommand:
    def __init__(self, parent):
        if not isinstance(parent, MachoFile):
            sys.exit("Error - Unsupported data type")
        self.cmd = 0x1000
        self.cmdsize = 8
        parent.insertCmd(self)
    
    def serialization(self):
        p = pack('=LL', self.cmd, self.cmdsize)
        return p
    
    def output(self):
        pprint (vars(self))

class LCSection:
    def __init__( self, parent, name, addr, payload , align=10, flags=0, final=None ):
        if( not isinstance(payload, bytearray)
           and not isinstance(payload, str)
           and not isinstance(parent, LCSegmentCommand) ):
            sys.exit("Error - Unsupported data type")
        self.segname = parent.segname
        self.sectname = name
        self.obj_size = 68
        self.addr = addr
        self.size = len(payload)
        self.offset = 0
        self.align = align
        self.reloff = 0
        self.nreloc = 0
        self.flags = flags
        self.reserved0 = 0
        self.reserved1 = 0
        self.payload = payload
        parent.insertSection(self, final)

    #return next valid offset, ref to payload
    def updateOffset(self, new):
        self.offset = new
        return self.size + new

    def serialization(self):
        #Pack using standard size
        p = pack('=16s16sLLLLLLLLL',
                 self.sectname,
                 self.segname,
                 self.addr,
                 self.size,
                 self.offset,
                 self.align,
                 self.reloff,
                 self.nreloc,
                 self.flags,
                 self.reserved0,
                 self.reserved1 )
        return p

    def output(self):
        pprint (vars(self))


class LCSegmentCommand:
    def __init__(self, parent, name, addr, size):
        if not isinstance(parent, MachoFile):
            sys.exit("Unsupported format")
        self.cmd = 1
        self.cmdsize = 56
        self.segname = name
        self.vmaddr = addr
        self.vmsize = size
        self.maxprot = 0
        self.initprot = 0
        self.fileoff = 0
        self.filesize = 0
        self.nsec = 0
        self.flags = 0
        self.section_list = []
        self.parent = parent
    
    #insert a new LCSection
    def insertSection(self,section,final):
        if isinstance(section, LCSection):
            self.section_list.append(section)
            self.nsec = len(self.section_list)
            self.cmdsize+=section.obj_size
            if final:
                self.parent.insertCmd(self)

    def commit(self):
        self.parent.insertCmd(self)

    #return next valid offset, ref to payload
    def updateOffset(self, new):
        offset = new
        self.fileoff = offset
        for s in self.section_list:
            offset = s.updateOffset( offset )
        return offset

    def output(self):
        pprint (vars(self))
        for s in self.section_list:
            s.output()
                
    def serialization(self):
        p = []
        p.append( pack('=LL16sLLLLLLLL',
               self.cmd,
               self.cmdsize,
               self.segname,
               self.vmaddr,
               self.vmsize,
               self.fileoff,
               self.filesize,
               self.maxprot,
               self.initprot,
               self.nsec,
               self.flags) )
    
        for s in self.section_list:
            p.append( s.serialization() )
        return "".join(p)

class MachoFile:
    def __init__(self):
        self.header = MachoHeader()
        self.cmd_list = []
        self.payload_list = []
    #offset for packed size of header:
    
    #notify all commands of the start offset
    def commit(self):
        #Propagate offests to all child objects
        offset = self.header.size + self.header.sizeofcmds
        for cmd in self.cmd_list:
            #Commands with payloads
            if isinstance(cmd, LCSegmentCommand):
                offset = cmd.updateOffset(offset)

    def insertCmd(self,cmd):
        if  isinstance(cmd, FakeCommand) or \
            isinstance(cmd, LCSegmentCommand) or \
            isinstance(cmd, HBPPCommand) or \
            isinstance(cmd, PollDataCommand):
                self.cmd_list.insert( self.header.ncmd , cmd )
                self.header.ncmd+=1
                self.header.sizeofcmds += cmd.cmdsize

    def output(self):
        self.header.output()
        for i in self.cmd_list:
            i.output()
                
    def flushToDisc(self, filename):
        #update data structures
        self.commit()
        #open
        fileh = open(filename, 'w')
        
        #Header, Commands, Payloads
        fileh.write( self.header.serialization() )
        
        for cmd in self.cmd_list:
            fileh.write( cmd.serialization() )
    
        for cmd in self.cmd_list:
            #Only commands with payloads:
            if isinstance(cmd, LCSegmentCommand):
                for s in cmd.section_list:
                    if isinstance(s.payload, bytearray):
                        data = bytes( str(s.payload) )
                        fileh.write( data )
                    if isinstance(s.payload, str):
                        fileh.write( s.payload )
        fileh.close()

def performTest(macho, args):
    cmd = args.pop(0)
    if cmd == "simple":
        t = LCSegmentCommand(macho, "__DATACORRUPT", int(0x300000), 448*1024)
        s = LCSegmentCommand(macho, "__TEXT", int(0x100000), 448*1024)
        r = LCSegmentCommand(macho, "__DATA", int(0x200000), 448*1024)

        LCSection(s, "__text", int(0x100000), bytearray(1024) )
        LCSection(s, "__text2",int(0x100400), bytearray(1024) )
        s.commit()

        H = HBPPCommand(macho)
        HBPPOperation( H, opcode=255, address=int(0x100000) , bitmask=int(0x3444), compare=int(0x2000) )
        HBPPOperation( H, opcode=255, address=int(0x108000) , bitmask=int(0x3444), compare=int(0x2000) )
        HBPPOperation( H, opcode=255, address=int(0x10F000) , bitmask=int(0x3444), compare=int(0x2000) )
        H.commit()

        LCSection(r, "__data", int(0x200000), bytearray(1024) )
        LCSection(r, "__data2",int(0x200400), bytearray(1024) )
        r.commit()

        LCSection(t, "__datacorrupt", int(0x200000), bytearray(1024), flags=int(0xFEEBFEEB) )
        LCSection(t, "__datacorrupt2",int(0x200400), bytearray(1024), flags=int(0xBEEFBEEF) )
        t.commit()
        return
    
    if cmd == "hbpp":
        print "Running HBPP test"
        H = HBPPCommand(macho)
        HBPPOperation( H, opcode=511, address=int(0x100000) )
        HBPPOperation( H, opcode=255, address=int(0x104000) , bitmask=int(0x3444), compare=int(0x2000) )
        H.commit()
        return

    if cmd == "1":
        addr = int(0x10000)
        mask = int(0xCAFEF00D)
        for x in range(0, 3):
            x = HBPPCommand(macho)
            for y in range(0, 5):
                q = HBPPOperation( x, opcode=255, address=addr , bitmask=mask, compare=int(0x80000000) )
                addr += 1024
                mask -= 0xAFAF
                del q
            x.commit()
            del x
        return

    if cmd == "2":
        s = LCSegmentCommand(macho, "__TEXT", int(0x100000), 448*1024)
        LCSection(s, "__text", int(0x100000), bytearray(1024) )
        s.commit()

	s = LCSegmentCommand(macho, "__TEXT", int(0x100000), 448*1024)
        LCSection(s, "__text2",int(0x100400), bytearray(1024) )
	s.commit()

        H = HBPPCommand(macho)
        HBPPOperation( H, opcode=255, address=int(0x100000) , bitmask=int(0x3444), compare=int(0x2000) )
        HBPPOperation( H, opcode=255, address=int(0x102000) , bitmask=int(0x3444), compare=int(0x2000) )
        H.commit()

	s = LCSegmentCommand(macho, "__TEXT", int(0x100000), 448*1024)
        LCSection(s, "__text3",int(0x100600), bytearray(1024) )
	s.commit()

        H = HBPPCommand(macho)
        HBPPOperation( H, opcode=255, address=int(0x100000) , bitmask=int(0x3444), compare=int(0x2000) )
        HBPPOperation( H, opcode=255, address=int(0x101000) , bitmask=int(0x3444), compare=int(0x2000) )
        HBPPOperation( H, opcode=255, address=int(0x102000) , bitmask=int(0x3444), compare=int(0x2000) )
        H.commit()
        return


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='Generate Macho Files for Midos')
    ap.add_argument('-o', '--output', help='output macho file name', action='store', dest='outfile')
    ap.add_argument('-i', '--input', help='binary, sectname, segname, address', action='store', dest='infile', nargs=4)
    ap.add_argument('-t', '--test', help='test case to run {simple, hbpp}', action='store', dest='test', nargs=1 )
    args = ap.parse_args()
    
    n = MachoFile()
    
    if args.test:
        performTest( n, args.test )
    
    #Input file specified, so tokenize
    if args.infile:
        print list(args.infile)
        fn = args.infile.pop(0)
        sect_name = args.infile.pop(0)
        seg_name = args.infile.pop(0)
        s_addr = int( args.infile.pop(0) )
        f = open(fn, 'r')
        b = f.read()
        f.close()
        del f
        sect = LCSegmentCommand(n, sect_name, s_addr, len(b) )
        seg = LCSection(sect, seg_name, s_addr, 10, b, 1 )

    if args.outfile:
        n.flushToDisc(args.outfile)
    else:
        print "No output file specified, done"

    del n
