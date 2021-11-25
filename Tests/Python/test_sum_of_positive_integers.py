#!/usr/bin/env python3

# 
# Use scipy to compute the sum of all positive integers: 1 + 2 + 3 + 4 ...
# Verify the correct value == -1/12
#

import sysconfig
import sys
import os

if sysconfig.get_config_var('TARGET_OS_EMBEDDED'):
    #skip test
    sys.exit(69)

import pip._internal

wheel = 'assets/scipy-1.2.1-cp37-cp37m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl'
if os.getenv("DT_ASSETS"):
    wheel = os.path.join(os.getenv("DT_ASSETS"), wheel)

pip._internal.main(['install', wheel])

from numpy import sin, pi
from scipy.special import gamma
from scipy.special import zeta as _zeta

def zeta(s):
    if s > 1:
        return _zeta(s)
    else:
        # scipy's zeta doesn't work in this range.
        # use Riemann's functional equation to evalute ζ(s) in terms of ζ(1-s)
        return 2**s * pi**(s-1) * sin(pi*s/2) * gamma(1-s) * zeta(1-s)


sum_of_integers = zeta(-1)

print(f"1 + 2 + 3 + 4 ... = {sum_of_integers}")

if abs(sum_of_integers - (-1.0/12)) < 1e-5:
    print("ok")
    sys.exit(0)
else:
    print("failed!")
    sys.exit(1)
