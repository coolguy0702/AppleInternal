import context
from context import unittest


class darwinunitWrapperPassingTestCases(unittest.TestCase):
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

    def testAdd(self):
        self.assertEqual((1 + 2), 3)
        self.assertEqual(0 + 1, 1, "simple addition")

    def testMultiply(self):
        self.assertEqual((0 * 10), 0)
        self.assertEqual((5 * 8), 40)

    def testAssertFalse(self):
        self.assertFalse(False)

    def testAssertTrue(self):
        self.assertTrue(True)

    def testExpectedRaise(self):
        with self.assertRaises(ZeroDivisionError):
            self.assertEqual(19, 38/2)
            p = 29/0
            print p
        self.assertRaises(ValueError, context.check_if_divisible_by_5, "five")

    def testAssertEqual(self):
        self.assertEqual(3*30, 90, 'value should be equal')

    def testAssertNotEqual(self):
        self.assertNotEqual(3*3, 90, 'value should not be equal')

    def testAssertAlmostEqual(self):
        self.assertAlmostEqual(2.99999999, 3)

    def testAssertNotAlmostEqual(self):
        self.assertNotAlmostEqual(3.93, 3)

    def testAssertSequenceEqual(self):
        self.assertSequenceEqual((1, 2), (1, 2), msg="The sequesces are equal")

    def testAssertListEqual(self):
        self.assertListEqual([1, 2, 1], [1, 2, 1], "The lists are equal")

    def testAssertTupleEqual(self):
        tup1 = ('A', 'B', 1, 2)
        self.assertTupleEqual(tup1, tup1, "The tuples are equal")

    def testAssertSetEqual(self):
        set1 = set([3, 1, 3, 2])
        set2 = set([1, 2, 3, 3])
        self.assertSetEqual(set1, set2, "The sets are equal")

    def testAssertIn(self):
        self.assertIn(3, set([1, 2, 3, 4]))

    def testAssertNotIn(self):
        self.assertNotIn(7, set([1, 2, 3, 4]))

    def testAssertIs(self):
        self.assertIs(45/9, 5)

    def testAssertIsNot(self):
        self.assertIsNot(45/9, 6)

    def testAssertDictEqual(self):
        self.assertDictEqual({'a': 1, 'b': [1, 2]}, {'b': [1, 2], 'a': 1})

    def testAssertDictContainsSubset(self):
        self.assertDictContainsSubset({'abc': 1}, {'abc': 1, 'def': [1, 2]})

    def testAssertItemsEqual(self):
        self.assertItemsEqual({'abc': 1, 'def': [1, 2]}, {'def': [2, 1], 'abc': 1})

    def testAssertMultiLineEqual(self):
        a = '123456\nxax\naaa\n'
        self.assertMultiLineEqual(a, a)

    def testAssertLess(self):
        self.assertLess(5+8, 15)

    def testAssertLessEqual(self):
        self.assertLessEqual(5+8, 13)

    def testAssertGreater(self):
        self.assertGreater(5+8, 11)

    def testAssertGreaterEqual(self):
        self.assertGreaterEqual(5+8, 13)

    def testAssertIsNone(self):
        self.assertIsNone(None)

    def testAssertIsNotNoneEqual(self):
        self.assertIsNotNone(0)

    def testAssertIsInstance(self):
        test_obj = context.DummyClass()
        self.assertIsInstance(test_obj, context.DummyClass)

    def testAssertNotIsInstance(self):
        test_obj = context.DummyClass()
        self.assertNotIsInstance(test_obj, darwinunitWrapperPassingTestCases)

    def testAssertRaisesRegexp(self):
        self.assertRaisesRegexp(ValueError, "'.*' is not a number!",
                                context.check_if_divisible_by_5, "five")


if __name__ == '__main__':
    unittest.main(verbosity=3)
