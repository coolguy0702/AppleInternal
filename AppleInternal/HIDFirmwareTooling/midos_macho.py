#!/usr/bin/python

import objc, argparse, sys, os
from Foundation import NSDictionary, NSData, NSDataWritingAtomic
from ctypes import c_uint32, cdll, c_void_p
import pymage4
from hbpp import *
from MachoBuilder import *
from im4p import *

# IM4P / PLIST to Midos Mach-o image conversion

MACHO_HBPP_SKIP_ACK_CHECK_MASK  = (1 << 31)
MACHO_CMD_POLL                  = 0x80
MACHO_POLL_MULTIPLIER           = 100
MACHO_REQ_CAL_MULTIPLIER        = 100000

class MidosImageBuilder:

    def __init__(self, max_payload_size, hbpp_ver):
        self.macho          = MachoFile()
        self.chunk_size     = max_payload_size
        self.hbpp_ver       = hbpp_ver
        self.cmd_ctx        = None

    def MidosByteSwap(self, data):
        curr_byte = 0
        swapped_data = []
        while (curr_byte < (len(data) - 1)):
            swapped_data += data[curr_byte + 1]
            swapped_data += data[curr_byte]
            curr_byte = curr_byte + 2
        return swapped_data

    def MidosProcessPayload(self, data, base_addr):
        byte_cnt        = 0
        curr_addr       = base_addr
        hbpp_file       = []
        buff_sz         = len(data)
        byte_processed  = 0

        # Compute how many packets will be needed to carry the data
        packet_cnt = buff_sz / self.chunk_size;
        if ((packet_cnt * self.chunk_size) < buff_sz):
             packet_cnt += 1

        h = hbpp_builder(self.hbpp_ver)

        # Process buffer
        for curr_packet in range(0, packet_cnt):

            # Grab a slice of the input buffer
            payload         = data[byte_processed : byte_processed + self.chunk_size]

            # HBPP encode
            hbpp_file       += h.data_pkt(payload, curr_addr)

            curr_addr       += len(payload)
            byte_processed  += len(payload)

        return hbpp_file

    def process(self, entry):
        # RMW command
        if (entry.get(IM4P_TAG_TYPE) == IM4P_TAG_TYPE_RMW):

            if (self.cmd_ctx == None):
                self.cmd_ctx = HBPPCommand(self.macho)

            opcode = HBPP_RMW_CMD

            if (True == entry.get(IM4P_TAG_SKIP_ACK)):
                opcode |= MACHO_HBPP_SKIP_ACK_CHECK_MASK

            HBPPOperation(
                self.cmd_ctx,
                opcode=int(opcode),
                address=int(entry.get(IM4P_TAG_ADDR)),
                bitmask=int(entry.get(IM4P_TAG_MASK)),
                compare=int(entry.get(IM4P_TAG_VALUE)))

        # Request Calibration
        elif (entry.get(IM4P_TAG_TYPE) == IM4P_TAG_TYPE_REQ_CAL):

            if (self.cmd_ctx == None):
                self.cmd_ctx = HBPPCommand(self.macho)

            opcode = HBPP_REQ_CAL_CMD

            HBPPOperation(
                self.cmd_ctx,
                opcode=int(opcode),
                address=int(0),
                bitmask=int(0),
                compare=int(0),
		delay=MACHO_REQ_CAL_MULTIPLIER)

        # Poll command
        elif (entry.get(IM4P_TAG_TYPE)  == IM4P_TAG_TYPE_POLL):

            if (self.cmd_ctx == None):
                self.cmd_ctx = HBPPCommand(self.macho)

            opcode = MACHO_CMD_POLL

            if (True == entry.get(IM4P_TAG_SKIP_ACK)):
                opcode |= MACHO_HBPP_SKIP_ACK_CHECK_MASK

            HBPPOperation(
                self.cmd_ctx,
                opcode=int(opcode),
                address=int(entry.get(IM4P_TAG_ADDR)),
                bitmask=int(entry.get(IM4P_TAG_MASK)),
                compare=int(entry.get(IM4P_TAG_VALUE)),
                delay=MACHO_POLL_MULTIPLIER)

        elif (entry.get(IM4P_TAG_TAG) == IM4P_TAG_TYPE_READ_ON_ERROR):
            # Boot trace buffer address
            print 'Located bootloader trace/error buffer at address ' + format(entry.get(IM4P_TAG_ADDR), '#08x')
            PollDataCommand(int(entry.get(IM4P_TAG_ADDR)), self.macho)

        # Binary
        elif ((entry.get(IM4P_TAG_TYPE) == IM4P_TAG_TYPE_BIN) or (entry.get(IM4P_TAG_TYPE) == IM4P_TAG_TYPE_PROP)):

            # A property could have an empty payload, in that case, skip
            if ((entry.get(IM4P_TAG_TYPE) == IM4P_TAG_TYPE_PROP) and (None == entry.get(IM4P_TAG_PAYLOAD, None))):
                print 'Skipping property with no payload'
                return

            if (self.cmd_ctx != None):
                self.cmd_ctx.commit()
                self.cmd_ctx = None

            # Address and Size not used
            data_section = LCSegmentCommand(self.macho, "__TEXT", int(0x100000), 448*1024)

            hbpp_img = self.MidosProcessPayload(entry.get(IM4P_TAG_PAYLOAD), entry.get(IM4P_TAG_ADDR))

            hbpp_img = self.MidosByteSwap(hbpp_img)

            LCSection(data_section, str(entry.get(IM4P_TAG_TAG)), entry.get(IM4P_TAG_ADDR), bytearray(hbpp_img), 0)

            data_section.commit();

    def commit(self, outputfile):
        if (self.cmd_ctx != None):
            self.cmd_ctx.commit()
        self.macho.flushToDisc(outputfile)

def midos_macho_gen(input_file, output_file=None, hbpp_version=14, max_hbpp_packet_sz=1024, personality=None):

    if (os.path.splitext(input_file)[1] == '.im4p'):
        src_img = pymage4.readImage(input_file)
    elif (os.path.splitext(input_file)[1] == '.plist'):
        src_img = NSDictionary.dictionaryWithContentsOfFile_(input_file)
    else:
        assert 0, unicode('Aborting, unknown input file')

    if (None == personality):
        # No specific personality requested, got through the whole file
        personalities = src_img.keys()
    else:
        # Process only specified personality
        personalities = [personality]

    for personality in personalities:

        midos_img = MidosImageBuilder(max_hbpp_packet_sz, hbpp_version)

        for entry in src_img[personality]:
            midos_img.process(entry)

        if (None == output_file):
            # If no output file is specified, use input file base name
            output_file_prefix = os.path.splitext(input_file)[0]
            output = output_file_prefix+'_'+personality+'.macho'
        else:
            output = output_file

        midos_img.commit(output)


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='Generate firmware image')

    # Personality
    ap.add_argument('--personality',            help='Personality to use', action='store', required=False, default=None)

   # HBPP version
    ap.add_argument('--hbpp_ver',               help='HBPP version (13 or 14)', action='store', required=False, default=14)

    # Midos max HBPP transaction size
    ap.add_argument('--midos_max_hbbp_sz',      help='Max HBPP packet size', action='store', required=False, default=1024)

    # Source IM4P
    ap.add_argument('--input',                  help='Path of input file (*.macho or *.im4p)', action='store', required=True)

    # Output file
    ap.add_argument('--output',                 help='Path of the output Mach-o', action='store', required=False, default=None)

    args = ap.parse_args()

    hbpp_version            = args.hbpp_ver
    max_hbpp_packet_sz      = args.midos_max_hbbp_sz
    personality             = args.personality
    input_file              = args.input
    output_file             = args.output

    midos_macho_gen(input_file, output_file, hbpp_version, max_hbpp_packet_sz, personality)
