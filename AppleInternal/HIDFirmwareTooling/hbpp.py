#!/usr/bin/python

# Handle packaging of data packets to HBPP frames. Supports HBPP 1.3 and 1.4
# Not a freestanding script

from struct import *

HBPP_VERSION_13     = 13
HBPP_VERSION_14     = 14

HBPP_MEMWR_CMD      = 0x5
HBPP_RMW_CMD        = 0x6
HBPP_REQ_CAL_CMD    = 0x7

HBPP_CMD_DATA_SEND  = 0x3001

class hbpp_builder:
    'Python HBPP builder'

    def __init__(self, version):
        if (version != HBPP_VERSION_13 and version != HBPP_VERSION_14):
            raise Exception("Invalid HBPP version")
        self.version = version

    def __data_size_get(self, data):
        data_size_word = len(data) >> 2
        if (self.version == HBPP_VERSION_14):
            data_size_word = data_size_word - 1
        return data_size_word

    def __checksum(self, data):
        checksum = sum(bytearray(data))
        return checksum

    def data_pkt(self, raw_buf, dst_addr):

        data = raw_buf.tobytes()

        # Command
        frame_cmd = pack("H", HBPP_CMD_DATA_SEND)

        # Ensure data is a multiple of 4 bytes
        if (len(data) & 0x3):
            padded_size = (len(data) & ~0x3) + 4
            print 'Adjusting unaligned buffer from 0x%08X to 0x%08X' % ((len(data)),padded_size)
            data = data.ljust(padded_size, '\0');

        # Frame size
        frame_hdr  = pack("H", self.__data_size_get(data))

        # Destination address
        frame_hdr += pack("H", dst_addr & 0xFFFF)
        frame_hdr += pack("H", dst_addr >> 16)

        # Header checksum (16-bit)
        frame_hdr += pack("H", self.__checksum(frame_hdr) & 0xFFFF)

        # Payload checksum (32-bit)
        payload_checksum = self.__checksum(data)
        frame_ftr  = pack("H", payload_checksum & 0xFFFF)
        frame_ftr += pack("H", payload_checksum >> 16)

        return (frame_cmd + frame_hdr + data + frame_ftr)
