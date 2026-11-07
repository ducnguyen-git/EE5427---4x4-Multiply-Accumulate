import unittest
from unittest.mock import patch

from main import compute, multiply, validate_matrix


class FakePort:
    baudrate = 9600

    def __init__(self, response):
        self.response = bytearray(response)
        self.sent = bytearray()

    def write(self, data):
        self.sent.extend(data)
        return len(data)

    def flush(self):
        pass

    def read(self, size):
        # Exercise partial serial reads, including the empty timeout response.
        chunk = self.response[:1]
        del self.response[:1]
        return chunk


class MatrixTests(unittest.TestCase):
    def test_reference(self):
        a = [[4 * r + c for c in range(4)] for r in range(4)]
        identity = [[int(r == c) for c in range(4)] for r in range(4)]
        self.assertEqual(multiply(a, identity), a)
        self.assertEqual(multiply([[15] * 4] * 4, [[15] * 4] * 4), [[900] * 4] * 4)
        self.assertEqual(multiply(a, [[0] * 4] * 4), [[0] * 4] * 4)

    @patch("main.time.sleep")
    def test_wire_protocol(self, sleep):
        a = [[4 * r + c for c in range(4)] for r in range(4)]
        b = [row[::-1] for row in a]
        # Distinct 10-bit values expose byte order and row/column swaps.
        values = [256 + 17 * i for i in range(16)]
        port = FakePort(b"".join(v.to_bytes(2, "little") for v in values))
        self.assertEqual(compute(port, a, b), [values[r:r + 4] for r in range(0, 16, 4)])
        expected = bytes([0] + sum(a, []) + sum(b, []) + [1]
                         + [v for i in range(16) for v in (2, i)])
        self.assertEqual(port.sent, expected)
        self.assertGreaterEqual(sleep.call_args_list.count(unittest.mock.call(50 / 9600)), 2)

    @patch("main.time.sleep")
    def test_bad_response(self, sleep):
        matrix = [[0] * 4] * 4
        for response, error in ((b"", TimeoutError), (b"\x00", TimeoutError),
                                (b"\x00\x04", ValueError)):
            with self.subTest(response=response), self.assertRaises(error):
                compute(FakePort(response), matrix, matrix)

    def test_validation_before_write(self):
        for matrix in ([], [[0] * 3] * 4, [[16] * 4] * 4,
                       [[-1] * 4] * 4, [[1.5] * 4] * 4):
            with self.subTest(matrix=matrix), self.assertRaises(ValueError):
                validate_matrix(matrix)


if __name__ == "__main__":
    unittest.main()
