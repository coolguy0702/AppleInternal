import os
import sys
import unittest


here = os.path.dirname(__file__)
loader = unittest.defaultTestLoader

def suite():
    suite = unittest.TestSuite()
    for fn in os.listdir(here):
        if fn.startswith("test") and fn.endswith(".py"):
            modname = __name__ + "." + fn[:-3]
            __import__(modname)
            module = sys.modules[modname]
            suite.addTest(loader.loadTestsFromModule(module))
    suite.addTest(loader.loadTestsFromName(__name__ + '.testmock'))
    return suite

def load_tests(*_):
    return suite()

if __name__ == "__main__":
    unittest.main(defaultTest="suite")