from __future__ import print_function, unicode_literals

try:
    from darwintest import unittest
except ImportError:
    import unittest


class TestStringMethods(unittest.TestCase):

    def test_upper(self):
        self.assertEqual('foo'.upper(), 'FOO')

    def test_isupper(self):
        self.assertTrue('FOO'.isupper())
        self.assertFalse('Foo'.isupper())

    def test_split(self):
        s = 'hello world'
        self.assertEqual(s.split(), ['hello', 'world'])
        # make sure that s.split() fails when the sep is not a str
        with self.assertRaises(TypeError):
            s.split(2)


if __name__ == '__main__':
    print("unittest is imported from {}".format(unittest.__file__))
    unittest.main()
