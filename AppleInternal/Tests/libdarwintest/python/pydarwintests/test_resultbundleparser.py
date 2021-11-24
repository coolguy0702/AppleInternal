from __future__ import print_function, unicode_literals

import datetime
import context  # noqa
from darwintest import unittest
from darwintest.resultbundle import TestResultBundle
import os

TESTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)))
RBV2_PATH = os.path.join(TESTS_DIR, "assets", "resultbundle_v2")
RBV1_PATH = os.path.join(TESTS_DIR, "assets", "resultbundle_v1")


class TestVerifyResultBundleV2(unittest.TestCase):

    def test_parseRBDir(self):
        rb = TestResultBundle.ParseBundle(RBV2_PATH)
        print(rb)
        self.assertEqual(rb.testName, "lte_test_runner_helper_tests.perf_data")
        self.assertFalse(rb.runAsRoot)
        self.assertEqual(rb.testStatus, "PASS")
        self.assertEqual(rb.resultCode, 200)
        self.assertEqual(rb.beginTime, datetime.datetime(2019, 10, 7, 10, 31, 38, 312000))
        self.assertEqual(rb.endTime, datetime.datetime(2019, 10, 7, 10, 31, 38, 325000))

        expected_command = "/AppleInternal/Tests/libdarwintest/lte/lte_test_runner_helper_tests " \
                           "-n libdarwintest.lte_helper.perf_data"
        self.assertEqual(rb.command, expected_command)

        expected_argv = [
            "/AppleInternal/Tests/libdarwintest/lte/lte_test_runner_helper_tests",
            "-n",
            "libdarwintest.lte_helper.perf_data"
        ]
        self.assertEqual(rb.argv, expected_argv)

        rdb_data = rb.extractBATSinfo()
        self.assertEqual(rdb_data['test_id'], "lte_test_runner_helper_tests.perf_data")
        self.assertEqual(rdb_data['result_code'], 200)
        self.assertEqual(rdb_data["result_started"], "2019-10-07T10:31:38.312-07:00")


class TestVerifyResultBundleV1(unittest.TestCase):

    def test_parseRBDir(self):
        rb = TestResultBundle.ParseBundle(RBV1_PATH)
        print(rb)
        self.assertEqual(rb.testName, "lte_test_runner_helper_tests.perf_data")
        self.assertFalse(rb.runAsRoot)
        self.assertEqual(rb.testStatus, "PASS")
        self.assertEqual(rb.resultCode, 200)

        expected_command = "/AppleInternal/Tests/libdarwintest/lte/lte_test_runner_helper_tests " \
                           "-n libdarwintest.lte_helper.perf_data"
        self.assertEqual(rb.command, expected_command)

        expected_argv = [
            "/AppleInternal/Tests/libdarwintest/lte/lte_test_runner_helper_tests",
            "-n",
            "libdarwintest.lte_helper.perf_data"
        ]
        self.assertEqual(rb.argv, expected_argv)

        self.assertEqual(rb.beginTime, datetime.datetime(2019, 10, 7, 14, 10, 15, 429000))
        self.assertEqual(rb.endTime, datetime.datetime(2019, 10, 7, 14, 10, 15, 575000))

        rdb_data = rb.extractBATSinfo()
        self.assertEqual(rdb_data['test_id'], "lte_test_runner_helper_tests.perf_data")
        self.assertEqual(rdb_data['result_code'], 200)
        self.assertEqual(rdb_data["result_started"], "2019-10-07T14:10:15-07:00")


if __name__ == '__main__':
    print("unittest is imported from {}".format(unittest.__file__))
    unittest.main()
