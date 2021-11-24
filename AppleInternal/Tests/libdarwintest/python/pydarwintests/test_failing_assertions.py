import context
from context import unittest


class NewException(Exception):
    pass


class darwinunitWrapperFailingTestCases(unittest.TestCase):
    currentResult = None  # holds last result object passed to run method

    @classmethod
    def setResult(cls, amount, errors, failures, skipped):
        cls.amount, cls.errors, cls.failures, cls.skipped = \
            amount, errors, failures, skipped

    def tearDown(self):
        amount = self.currentResult.testsRun
        errors = self.currentResult.errors
        failures = self.currentResult.failures
        skipped = self.currentResult.skipped
        self.setResult(amount, errors, failures, skipped)

    @classmethod
    def tearDownClass(cls):
        print("\n\n{t:12s}: {tn}".format(t="total tests", tn=cls.amount))
        print("{p:12s}: {pn}".format(p="success", pn=(cls.amount - len(cls.errors) - len(cls.failures))))
        print("{e:12s}: {en}".format(e="errors", en=len(cls.errors)))
        print("{f:12s}: {fn}".format(f="failures", fn=len(cls.failures)))
        print("{x:12s}: {xn}".format(x="skipped", xn=len(cls.skipped)))

    def run(self, result=None):
        self.currentResult = result  # remember result for use in tearDown
        unittest.TestCase.run(self, result)  # call superclass run method

    def testAssertFalseFailure(self):
        self.assertFalse(True, "True is not false")

    def testAssertTrueFailure(self):
        self.assertTrue(False, "False is not true")

    def testExpectedRaiseFailure(self):
        with self.assertRaises(ZeroDivisionError):
            self.assertEqual(19, 38/2)
            p = 29/0
            print p
        self.assertRaises(ValueError, context.check_if_divisible_by_5, 5)

    def testAssertEqualFailure(self):
        self.assertEqual(3*30, 9, 'value is not equal')

    def testAssertNotEqualFailure(self):
        self.assertNotEqual(3*3, 9, 'value is equal')

    def testAssertAlmostEqualFailure(self):
        self.assertAlmostEqual(3.93, 3)

    def testAssertNotAlmostEqualFailure(self):
        self.assertNotAlmostEqual(3.0, 3)

    def testAssertSequenceEqualFailure(self):
        self.assertSequenceEqual((1, 2), (2, 1), msg="The sequesces are not equal")

    def testAssertListEqualFailure(self):
        self.assertListEqual([1, 2], [2, 3], "The lists are not equal")

    def testAssertTupleEqualFailure(self):
        tup1 = ('A', 'B', 1, 2)
        tup2 = ('B', 'A', 2, 1)
        self.assertTupleEqual(tup1, tup2, "The tuples are not equal")

    def testAssertSetEqualFailure(self):
        set1 = set([3, 1, 3, 2])
        set2 = set([1, 2, 3, 4])
        self.assertSetEqual(set1, set2, "The sets are not equal")

    def testAssertInFailure(self):
        self.assertIn(7, set([1, 2, 3, 4]))

    def testAssertNotInFailure(self):
        self.assertNotIn(3, set([1, 2, 3, 4]))

    def testAssertIsFailure(self):
        self.assertIs(45/9, 6)

    def testAssertIsNotFailure(self):
        self.assertIsNot(45/9, 5)

    def testAssertDictEqualFailure(self):
        self.assertDictEqual({'a': 1, 'b': [1, 2]}, {'a': 1, 'b': [1]})

    def testAssertDictContainsSubsetFailure(self):
        self.assertDictContainsSubset({'abc': 1, 'def': [1, 2]}, {'abc': 1})

    def testAssertItemsEqualFailure(self):
        self.assertItemsEqual({'abc': 1, 'def': [1, 2]}, {'abc': 1})

    def testAssertMultiLineEqualFailure(self):
        a = '1234561\nxax\naaa\n'
        b = '1234560\nxax\naaa\n'
        self.assertMultiLineEqual(a, b)

    def testAssertLessFailure(self):
        self.assertLess(5+8, 13)

    def testAssertLessEqualFailure(self):
        self.assertLessEqual(5+8, 12)

    def testAssertGreaterFailure(self):
        self.assertGreater(5+8, 13)

    def testAssertGreaterEqualFailure(self):
        self.assertGreaterEqual(5+8, 14)

    def testAssertIsNoneFailure(self):
        self.assertIsNone(0)

    def testAssertIsNotNoneEqualFailure(self):
        self.assertIsNotNone(None)

    def testAssertIsInstanceFailure(self):
        test_obj = context.DummyClass()
        self.assertIsInstance(test_obj, darwinunitWrapperFailingTestCases)

    def testAssertNotIsInstanceFailure(self):
        test_obj = context.DummyClass()
        self.assertNotIsInstance(test_obj, context.DummyClass)

    def testAssertRaisesRegexpFailure(self):
        self.assertRaisesRegexp(NewException, "'.*' is not a number!",
                                context.check_if_divisible_by_5, "five")

    def testSkipTest(self):
        self.assertTrue(4 == 4.0, "int and double are true")
        self.skipTest("Intentionally skip test")

    def testFailATest(self):
        self.fail("Failing this one intentionally")


if __name__ == '__main__':
    unittest.main(verbosity=3)
