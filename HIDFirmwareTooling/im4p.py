#!/usr/bin/python

import argparse
import base64
import logging
import os
import sys
from ctypes import c_uint32, cdll, c_void_p

import objc
from Foundation import NSDictionary, NSData, NSDataWritingAtomic
from boot_fifo import *

# Manages IM4P image creation

IM4P_TAG_FILE = 'File'
IM4P_TAG_PAYLOAD = 'Payload'
IM4P_TAG_TYPE = 'Type'
IM4P_TAG_ADDR = 'Address'
IM4P_TAG_MASK = 'Mask'
IM4P_TAG_VALUE = 'Value'
IM4P_TAG_MAXSIZE = 'MaxSize'
IM4P_TAG_TIMEOUT = 'TimeoutMs'
IM4P_TAG_DESCR = 'Description'
IM4P_TAG_SKIP_ACK = 'SkipCheck'
IM4P_TAG_PROPERTY = 'Property'
IM4P_TAG_SYSCFG_KEY = 'SysConfigKey'
IM4P_TAG_TAG = 'Tag'
IM4P_TAG_VALIDATION = 'Validation'

IM4P_TAG_TYPE_BIN = 'Binary'
IM4P_TAG_TYPE_PROP = 'Property'
IM4P_TAG_TYPE_RMW = 'ReadModifyWrite'
IM4P_TAG_TYPE_POLL = 'Poll'
IM4P_TAG_TYPE_REQ_CAL = 'RequestCalibration'
IM4P_TAG_TYPE_CONFIG = 'Config'
IM4P_TAG_TYPE_READ_ON_ERROR = 'ReadOnError'
IM4P_TAG_TYPE_METADATA = 'Metadata'
IM4P_TAG_TYPE_BOOTCONFIG = '_bootconfig'
IM4P_TAG_TYPE_BOOTLOADER = '_bootloader'
IM4P_TAG_TYPE_VECTORS = '_vectors'


class IM4PRecord(object):
    def __init__(self, type, comment=None):
        self.record = {
            IM4P_TAG_TYPE: type,
            IM4P_TAG_DESCR: str(comment) if comment else self.__class__,
        }
        logging.debug('Generating {0}'.format(self.__class__))

    def __str__(self):
        return str(self.ns_dictionary())

    def ns_dictionary(self):
        return NSDictionary.dictionaryWithDictionary_(self.record)


class IM4PPoll(IM4PRecord):
    def __init__(self, address, mask, value, read_on_error, comment=None, timeout=100):
        IM4PRecord.__init__(self, type=IM4P_TAG_TYPE_POLL, comment=comment)
        self.record.update({IM4P_TAG_ADDR: address,
                            IM4P_TAG_MASK: mask,
                            IM4P_TAG_VALUE: value,
                            IM4P_TAG_TIMEOUT: timeout,
                            IM4P_TAG_TYPE_READ_ON_ERROR: read_on_error})


class IM4PReadModWrite(IM4PRecord):
    def __init__(self, address, mask, value, skip_check=False, comment=None):
        IM4PRecord.__init__(self, type=IM4P_TAG_TYPE_RMW, comment=comment)
        self.record.update({IM4P_TAG_ADDR: address,
                            IM4P_TAG_MASK: mask,
                            IM4P_TAG_VALUE: value,
                            IM4P_TAG_SKIP_ACK: skip_check})


class IM4PReadOnError(IM4PRecord):
    def __init__(self, address):
        IM4PRecord.__init__(self, type=IM4P_TAG_TYPE_METADATA, comment='Read On Error: Addr:0x{0:08X}'.format(address))
        self.record.update({IM4P_TAG_TAG: IM4P_TAG_TYPE_READ_ON_ERROR,
                            IM4P_TAG_ADDR: address})


class IM4PHBPPData(IM4PRecord):
    def __init__(self, address, payload, tag, name=None):
        IM4PRecord.__init__(self, type=IM4P_TAG_TYPE_BIN,
                            comment='BINARY [{0} Addr:0x{1:08X} Size:{2}]'.format(name if name else 'Unknown',
                                                                                  address,
                                                                                  len(payload)))
        self.record.update({IM4P_TAG_ADDR: address,
                            IM4P_TAG_PAYLOAD: bytearray(payload),
                            IM4P_TAG_TAG: tag,
                            IM4P_TAG_MAXSIZE: len(payload)})


class im4p_builder:
    # 'Python IM4P builder'

    def __init__(self):
        self.img = {}
        self.personality = None

    def __iadd__(self, other):
        # Add classes above
        if isinstance(other, IM4PRecord):
            logging.info('Adding {0}'.format(other.__class__))
            logging.debug(other)
            self.img[self.personality].extend([other.record])
            return self

        # Add a personality string
        if isinstance(other, str):
            self.personality = other
            self.img.update({self.personality: []})
            return self

        raise TypeError('Unsupported data type')

    def AddPersonality(self, personality):
        self.personality = personality
        self.img.update({self.personality: []})

    def Select(self, personality):
        self.personality = personality

    def AddData(self, data, address, description, tag=""):
        data_type = FIFO_TYPE_BIN
        payload = []
        fifo_header = None
        fifo_payload = None

        if not isinstance(data, str):
            # Coming from FIFO builder
            fifo_header = data.get(FIFO_HEADER, None)
            fifo_payload = data.get(FIFO_PAYLOAD, None)
            data_type = data.get(FIFO_TYPE, None)
            # Overwrite description with original name
            tag = description + '_' + data.get(FIFO_DESCRIPTION, None)
            description = description + '_' + data.get(FIFO_DESCRIPTION, None)

            if fifo_header:
                payload = bytearray(fifo_header)

            if fifo_payload:
                payload += bytearray(fifo_payload)

        else:
            payload = bytearray(data)

        if data_type == FIFO_TYPE_PROP \
                and fifo_header \
                and fifo_payload:
            # Properties get special treatment, header is sent as binary
            # payload is sent as property
            self.img[self.personality].extend([{
                IM4P_TAG_TYPE: IM4P_TAG_TYPE_BIN,
                IM4P_TAG_DESCR: description,
                IM4P_TAG_PAYLOAD: bytearray(fifo_header),
                IM4P_TAG_ADDR: address,
                IM4P_TAG_MAXSIZE: FIFO_HEADER_SIZE,
                IM4P_TAG_TAG: tag + '_property'
            }])
            self.AddProperty(address + FIFO_HEADER_SIZE,
                             fifo_payload,
                             data.get(FIFO_PROPERTY_STR),
                             data.get(FIFO_SYSCFG_KEY),
                             description,
                             data.get(IM4P_TAG_MAXSIZE))
        else:
            # Regular payload
            self.img[self.personality].extend([{
                IM4P_TAG_TYPE: IM4P_TAG_TYPE_BIN,
                IM4P_TAG_DESCR: description,
                IM4P_TAG_PAYLOAD: payload,
                IM4P_TAG_ADDR: address,
                IM4P_TAG_MAXSIZE: len(payload),
                IM4P_TAG_TAG: tag
            }])

    def AddProperty(self, address, default_payload, property_str, sys_config_key, description, max_size):
        if default_payload:
            self.img[self.personality].extend([{
                IM4P_TAG_TYPE: IM4P_TAG_TYPE_PROP,
                IM4P_TAG_DESCR: description,
                IM4P_TAG_PAYLOAD: bytearray(default_payload),
                IM4P_TAG_ADDR: address,
                IM4P_TAG_MAXSIZE: max_size,
                IM4P_TAG_PROPERTY: property_str,
                IM4P_TAG_SYSCFG_KEY: sys_config_key
            }])
        else:
            self.img[self.personality].extend([{
                IM4P_TAG_TYPE: IM4P_TAG_TYPE_PROP,
                IM4P_TAG_DESCR: description,
                IM4P_TAG_ADDR: address,
                IM4P_TAG_MAXSIZE: max_size,
                IM4P_TAG_PROPERTY: property_str,
                IM4P_TAG_SYSCFG_KEY: sys_config_key
            }])

    def AddRMW(self, address, mask, value, SkipCheck=False):
        self.img[self.personality].extend([{
            IM4P_TAG_TYPE: IM4P_TAG_TYPE_RMW,
            IM4P_TAG_ADDR: address,
            IM4P_TAG_MASK: mask,
            IM4P_TAG_VALUE: value,
            IM4P_TAG_SKIP_ACK: SkipCheck
        }])

    @staticmethod
    def create_read_mod_write(address, mask, value, skipcheck=False, comment=None):
        d = {
            IM4P_TAG_TYPE: IM4P_TAG_TYPE_RMW,
            IM4P_TAG_ADDR: address,
            IM4P_TAG_MASK: mask,
            IM4P_TAG_VALUE: value,
            IM4P_TAG_SKIP_ACK: skipcheck
        }
        if isinstance(comment, str):
            d[IM4P_TAG_DESCR] = comment
        return NSDictionary.dictionaryWithDictionary_(d)

    def AddPoll(self, address, mask, value, timeout, read_on_error):
        self.img[self.personality].extend([{
            IM4P_TAG_TYPE: IM4P_TAG_TYPE_POLL,
            IM4P_TAG_ADDR: address,
            IM4P_TAG_MASK: mask,
            IM4P_TAG_VALUE: value,
            IM4P_TAG_TIMEOUT: timeout,
            IM4P_TAG_TYPE_READ_ON_ERROR: read_on_error
        }])

    @staticmethod
    def create_poll(address, mask, value, read_on_error, comment=None, timeout=1000, ):
        d = {
            IM4P_TAG_TYPE: IM4P_TAG_TYPE_POLL,
            IM4P_TAG_ADDR: address,
            IM4P_TAG_MASK: mask,
            IM4P_TAG_VALUE: value,
            IM4P_TAG_TIMEOUT: timeout,
            IM4P_TAG_TYPE_READ_ON_ERROR: read_on_error
        }
        if isinstance(comment, str):
            d[IM4P_TAG_DESCR] = comment
        return NSDictionary.dictionaryWithDictionary_(d)

    @staticmethod
    def create_binary(address, payload, description=None, tag=None):
        payload = bytearray(payload)
        d = {
            IM4P_TAG_TYPE: IM4P_TAG_TYPE_BIN,
            IM4P_TAG_PAYLOAD: payload,
            IM4P_TAG_ADDR: address,
            IM4P_TAG_MAXSIZE: len(payload),
        }

        if isinstance(tag, str):
            d[IM4P_TAG_TAG] = tag

        if isinstance(description, str):
            d[IM4P_TAG_DESCR] = description

        return NSDictionary.dictionaryWithDictionary_(d)

    def AddGeneric(self, entry):
        self.img[self.personality].extend([
            entry
        ])

    def Get(self):
        return self.img

    def Serialize(self, filepath):
        libIOKit = cdll.LoadLibrary('/System/Library/Frameworks/IOKit.framework/IOKit')
        libIOKit.IOCFSerialize.argtypes = [c_void_p, c_uint32]
        libIOKit.IOCFSerialize.restype = c_void_p

        output = NSDictionary.dictionaryWithDictionary_(self.img)

        serialized = libIOKit.IOCFSerialize(objc.pyobjc_id(output), 0)
        assert serialized != 0, 'Cannot serialize. Invalid dictionary'

        data = objc.objc_object(c_void_p=serialized)
        succeeded, errorMessage = data.writeToFile_options_error_(filepath, NSDataWritingAtomic, None)
        assert succeeded, unicode(errorMessage)
