#!/usr/bin/python

# Handle packaging of binaries & boot sequence commands in the bootloader FIFO format
# Not a freestanding script

from hbpp import *
from msg_log import *
from struct import *

# typedef enum _fifo_packet_type_t
# {
#    PACKET_TYPE_DATA_HBPP = 0x00,               /**< Packet is pre-packaged HBPP data frame */
#    PACKET_TYPE_DATA_RAW  = 0x01,               /**< Packet is raw HBPP data frame */
#    PACKET_TYPE_HBPP_CMD  = 0x02,               /**< Packet is HBPP command list*/
#    PACKET_TYPE_READ_CMD  = 0x03,               /**< Packet is read */
#    PACKET_TYPE_COUNT     = 0x04
# } fifo_packet_type_t;

# typedef struct _fifo_status_t
# {
#    uint32_t data_valid      : 1;               /**< Block contains valid date, set by host */
#    uint32_t last_packet     : 1;               /**< Last packet */
#    uint32_t block_processed : 1;               /**< Block has been processed, set by slave */
#    uint32_t reserved_0      : 5;               /**< Reserved */
#    uint32_t packet_type     : 8;               /**< Packet type */
#    uint32_t reserved_1      : 16;              /**< Reserved */
# } fifo_status_t;

# typedef struct _bl_fifo_hdr_t
# {
#    uint32_t status;
#    uint32_t data_sz;
#    uint32_t dst_addr;
# } bl_fifo_hdr_t;

# typedef struct _fifo_hbpp_cmd_list_hdr_t
# {
#    uint32_t             op_count;              /**< HBPP command list entry count */
#    fifo_hbpp_cmd_desc_t cmd_list[];            /**< HBPP command list*/
# } fifo_hbpp_cmd_list_hdr_t;

# typedef struct _fifo_hbpp_cmd_desc_t
# {
#    uint32_t op_code;                           /**< HBPP command op-code */
#    uint32_t addr;                              /**< Operation destination address within DSC address space */
#    uint32_t mask;                              /**< Mask */
#    uint32_t val;                               /**< Value */
#    uint32_t delay_us;                          /**< Delay in microsecond before next command */
#    uint32_t skip_ack;                          /**< Skip ACK check */
# } fifo_hbpp_cmd_desc_t;

FIFO_HEADER_SIZE = 3 * 4
HBPP_META_DATA_SIZE = 32

FIFO_STATUS_DATA_VALID_SHIFT = 0
FIFO_STATUS_LAST_PACKET_SHIFT = 1
FIFO_STATUS_BLOCK_PROCESSED_SHIFT = 2
FIFO_STATUS_PACKET_TYPE_SHIFT = 8

FIFO_PACKET_TYPE_DATA_HBPP = 0x00
FIFO_PACKET_TYPE_DATA_RAW = 0x01
FIFO_PACKET_TYPE_HBPP_CMD = 0x02
FIFO_PACKET_TYPE_READ_CMD = 0x03

HBPP_OP_SIZE = 6 * 4

HBPP_CMD_OPCODE = 'op'
HBPP_CMD_ADDR = 'addr'
HBPP_CMD_MASK = 'mask'
HBPP_CMD_VAL = 'val'
HBPP_CMD_DELAY = 'delay_us'
HBPP_CMD_SKIP_ACK = 'skip_ack'

FIFO_HEADER = 'Header'
FIFO_PAYLOAD = 'Payload'
FIFO_MAX_SIZE = 'MaxSize'
FIFO_TYPE = 'Type'
FIFO_TYPE_PROP = 'Property'
FIFO_TYPE_BIN = 'Binary'
FIFO_PROPERTY_STR = 'Property'
FIFO_SYSCFG_KEY = 'SysConfigKey'
FIFO_DESCRIPTION = 'Description'


class fifo_hdr:
    # 'FIFO header builder'

    def __init__(self, status, data_sz, dst_addr):
        self.hdr = pack("I", status)
        self.hdr += pack("I", data_sz)
        self.hdr += pack("I", dst_addr)

    def get(self):
        return self.hdr


class hbpp_cmd:
    # 'HBPP command builder'

    def __init__(self, op):
        self.op = op
        self.addr = 0x00000000
        self.mask = 0xFFFFFFFF
        self.val = 0x00000000
        self.delay_us = 0x00000000
        self.skip_ack = 0x00000000
        self.cmd = ""

    def addr_set(self, addr):
        if addr is not None:
            self.addr = addr

    def mask_set(self, mask):
        if mask is not None:
            self.mask = mask

    def val_set(self, val):
        if val is not None:
            self.val = val

    def delay_set(self, delay_us):
        if delay_us is not None:
            self.delay_us = delay_us

    def skip_ack_set(self, skip_ack):
        if skip_ack is not None:
            if skip_ack is True:
                self.skip_ack = 1

    def get(self):
        self.cmd = pack("I", self.op)
        self.cmd += pack("I", self.addr)
        self.cmd += pack("I", self.mask)
        self.cmd += pack("I", self.val)
        self.cmd += pack("I", self.delay_us)
        self.cmd += pack("I", self.skip_ack)
        return self.cmd


class fifo_builder:
    # 'Python boot FIFO image builder'

    def __init__(self, block_sz, hbpp_pkt=True, hbpp_ver=HBPP_VERSION_13, force_data_valid=False):
        self.block_sz = block_sz
        self.hbpp_ver = hbpp_ver
        self.hbpp_pkt = hbpp_pkt
        self.data_valid = force_data_valid

        MsgLog('========================================\n' +
                   '          FIFO Image Builder            \n' +
                   '=======================================\n' +
                   'FIFO block size: 0x%08X\n' +
                   'HBPP packets: %s\n' +
                   'HBPP version: %d\n' +
                   'Force data valid: %s\n' +
                   '========================================',
                   self.block_sz, self.hbpp_pkt, self.hbpp_ver, self.data_valid)

        self.block_payload_sz = 0
        self.curr_dst_addr = 0

    def __block_meta_sz_get(self):
        if self.hbpp_pkt:
            return HBPP_META_DATA_SIZE
        else:
            return FIFO_HEADER_SIZE

    def __hbpp_pkt_enable_get(self):
        return self.hbpp_pkt

    def __hbpp_pkt_enable_set(self, enable):
        self.hbpp_pkt = enable

    def __header_gen(self, pkt_type, pkt_sz, last_pkt):

        status = pkt_type << FIFO_STATUS_PACKET_TYPE_SHIFT

        if self.data_valid:
            status |= (1 << FIFO_STATUS_DATA_VALID_SHIFT)

        if last_pkt:
            status |= (1 << FIFO_STATUS_LAST_PACKET_SHIFT)

        MsgLog('Packet Status: 0x%08X\n' +
                   'Packet Size:   0x%08X\n' +
                   'Packet Dest:   0x%08X',
                   status, pkt_sz, self.curr_dst_addr)
        header = fifo_hdr(status, pkt_sz, self.curr_dst_addr)

        return header

    def property_buffer_gen(self, src_buf, dst_addr, prop_max_sz, property_str, sysconfig_key, last_block=False):
        # Save current HBPP packet enable status
        self.__hbpp_pkt_enable_get()

        # Disable HBPP packets for properties
        self.__hbpp_pkt_enable_set(False)

        output = []

        # Max block payload size, automatically adjusted from FIFO block size
        self.block_payload_sz = self.block_sz - self.__block_meta_sz_get()
        self.curr_dst_addr = dst_addr
        pkt_type = FIFO_PACKET_TYPE_DATA_RAW

        assert prop_max_sz < self.block_payload_sz, 'Property size greater than FIFO block payload size'

        # Generate FIFO header, data size is always set to property max size
        # Current block set to 0, this is purely informative
        header = self.__header_gen(pkt_type, prop_max_sz, last_block)

        # Append default data to header, if available
        if src_buf is not None:
            output.append({FIFO_HEADER: header.get(),
                           FIFO_PAYLOAD: src_buf,
                           FIFO_TYPE: FIFO_TYPE_PROP,
                           FIFO_MAX_SIZE: prop_max_sz,
                           FIFO_PROPERTY_STR: property_str,
                           FIFO_SYSCFG_KEY: sysconfig_key,
                           FIFO_DESCRIPTION: property_str})
        else:
            output.append({FIFO_HEADER: header.get(),
                           FIFO_TYPE: FIFO_TYPE_PROP,
                           FIFO_MAX_SIZE: prop_max_sz,
                           FIFO_PROPERTY_STR: property_str,
                           FIFO_SYSCFG_KEY: sysconfig_key,
                           FIFO_DESCRIPTION: property_str})

        return output

    def data_buffer_gen(self, src_buf, dst_addr, descritpion, max_payload_sz=0, last_block=False):
        output = []

        # Max block payload size, either automatically adjusted from FIFO block size
        # or user specified
        if 0 == max_payload_sz:
            self.block_payload_sz = self.block_sz - self.__block_meta_sz_get()
        else:
            self.block_payload_sz = min(max_payload_sz, (self.block_sz - self.__block_meta_sz_get()))

        self.curr_dst_addr = dst_addr
        buff_sz = len(src_buf)
        slice_sz = min(buff_sz, self.block_payload_sz)
        byte_processed = 0

        if self.hbpp_pkt:
            pkt_type = FIFO_PACKET_TYPE_DATA_HBPP
        else:
            pkt_type = FIFO_PACKET_TYPE_DATA_RAW

        # Compute how many blocks will be needed to carry the data
        block_cnt = buff_sz / slice_sz
        if (block_cnt * slice_sz) < buff_sz:
            block_cnt += 1

        for curr_block in range(0, block_cnt):
            # Grab a slice of the input buffer
            payload = src_buf[byte_processed: byte_processed + slice_sz]

            # Package data into HBPP frame if required
            if self.hbpp_pkt:
                h = hbpp_builder(self.hbpp_ver)
                payload = h.data_pkt(payload, self.curr_dst_addr)

            # Generate FIFO header, data size must include HBPP meta-data if any
            if last_block and (curr_block == (block_cnt - 1)):
                # Last block
                header = self.__header_gen(pkt_type, len(payload), True)
            else:
                header = self.__header_gen(pkt_type, len(payload), False)

            # Append new block
            output.append({FIFO_HEADER: header.get(),
                           FIFO_PAYLOAD: payload,
                           FIFO_TYPE: FIFO_TYPE_BIN,
                           FIFO_DESCRIPTION: descritpion})
            byte_processed += slice_sz
            self.curr_dst_addr += slice_sz
            slice_sz = min(buff_sz - byte_processed, self.block_payload_sz)

        return output

    def hbpp_cmd_list_gen(self, boot_seq, last_block=True):
        output = []

        # HBPP operation count
        op_count = len(boot_seq)

        header = self.__header_gen(FIFO_PACKET_TYPE_HBPP_CMD, op_count * HBPP_OP_SIZE, last_block)
        payload = pack("I", op_count)

        for op in boot_seq:
            cmd = hbpp_cmd(op.get(HBPP_CMD_OPCODE, None))
            cmd.addr_set(op.get(HBPP_CMD_ADDR, None))
            cmd.mask_set(op.get(HBPP_CMD_MASK, None))
            cmd.val_set(op.get(HBPP_CMD_VAL, None))
            cmd.delay_set(op.get(HBPP_CMD_DELAY, None))
            cmd.skip_ack_set(op.get(HBPP_CMD_SKIP_ACK, None))

            payload += cmd.get()

        output.append({FIFO_HEADER: header.get(),
                       FIFO_PAYLOAD: payload,
                       FIFO_TYPE: FIFO_TYPE_BIN,
                       FIFO_DESCRIPTION: 'DCS_HBPP_Command_List'})

        return output
