#!/usr/bin/python

# Copyright (C) 2017 Apple Inc. All rights reserved.
#
# This document is the property of Apple Inc.
# It is considered confidential and proprietary.
#
# This document may not be reproduced or transmitted in any form,
# in whole or in part, without the express written permission of
# Apple Inc.

# Handle packaging of binaries & boot sequence commands in the bootloader FIFO format
# Not a freestanding script
import os


class NSLogger:
    def __init__(self):
        try:
            if os.environ['VERBOSE']:
                self.logging_enabled = True
        except KeyError:
            self.logging_enabled = False

    # Instance method -- only to be used by professionals
    def _enable(self, en):
        self.logging_enabled = en

    # Instance method -- only to be used by professionals
    def _log(self, *args):
        if self.logging_enabled:
            print args[0] % args[1:]


# Public interface to log a message
def MsgLog(*args):
    m._log(*args)


# Public interface to enable/disable logging
def EnableLogging(en):
    m._enable(en)


# Global used by Msg class
m = NSLogger()

if __name__ == '__main__':
    MsgLog("Test")
