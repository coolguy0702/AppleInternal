import sys
import os


TESTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(TESTS_DIR, "../"))

if "darwinunit" in os.environ:
    from darwintest import unittest # noqa
else:
    import unittest # noqa


def check_if_divisible_by_5(param):
    """ This is simple funtion used to test assertions
    """
    try:
        return int(param) % 5 == 0
    except ValueError:
        raise ValueError("'{0}' is not a number!".format(param))


class DummyClass(object):
    def __init__(self):
        """ This is a dummy class for testing
        """
        return
