import argparse
import random
import sys
import time

import serial
from serial.tools import list_ports


def validate_matrix(matrix):
    if len(matrix) != 4 or any(len(row) != 4 for row in matrix):
        raise ValueError("Each matrix must have four rows of four integers.")
    if any(type(value) is not int or not 0 <= value <= 15
           for row in matrix for value in row):
        raise ValueError("Matrix elements must be integers from 0 to 15.")


def multiply(a, b):
    return [[sum(a[row][k] * b[k][col] for k in range(4))
             for col in range(4)] for row in range(4)]


def read_matrix(name):
    print(f"Enter matrix {name}: four rows, values 0–15 (spaces or commas).")
    rows = []
    for row in range(4):
        while True:
            try:
                values = [int(v) for v in input(f"  Row {row + 1}: ").replace(",", " ").split()]
                validate_matrix([values] * 4)
                rows.append(values)
                break
            except ValueError as error:
                print(error)
    return rows


def compute(port, a, b):
    validate_matrix(a)
    validate_matrix(b)
    character_time = 10 / port.baudrate

    def send(data):
        # RX uses a four-phase mailbox; leave time for acknowledgment per byte.
        for value in data:
            if port.write(bytes([value])) != 1:
                raise OSError("Incomplete serial write.")
            port.flush()
            time.sleep(character_time)

    send([0] + [v for matrix in (a, b) for row in matrix for v in row])
    time.sleep(5 * character_time)
    send([1])
    # No DONE/status response exists; the RTL requires five character times.
    time.sleep(5 * character_time)
    result = []
    for index in range(16):
        send([2, index])
        response = bytearray()
        while len(response) < 2:
            chunk = port.read(2 - len(response))
            if not chunk:
                raise TimeoutError(
                    f"Timed out reading C[{index // 4 + 1},{index % 4 + 1}] "
                    f"({len(response)}/2 bytes). Check baud, wiring, reset and FPGA bitstream."
                )
            response.extend(chunk)
        if response[1] > 3:
            raise ValueError(f"Invalid 10-bit FPGA response: {response.hex(' ')}")
        result.append(int.from_bytes(response, "little"))
        time.sleep(character_time)
    return [result[row:row + 4] for row in range(0, 16, 4)]


def show_matrix(name, matrix):
    print(name)
    for row in matrix:
        print("  " + " ".join(f"{value:4d}" for value in row))


def main():
    parser = argparse.ArgumentParser(description="Compare FPGA unsigned 4×4 matrix multiplication with Python.")
    parser.add_argument("--port", help="Serial port, e.g. /dev/ttyUSB0 or COM3")
    parser.add_argument("--list-ports", action="store_true")
    parser.add_argument("--baud", type=int, default=9600)
    parser.add_argument("--timeout", type=float, default=2.0, help="Serial read/write timeout in seconds")
    parser.add_argument("--random", type=int, metavar="COUNT", help="Run COUNT random matrix pairs instead of manual entry")
    parser.add_argument("--seed", type=int, help="Reproduce random inputs")
    args = parser.parse_args()
    if args.list_ports:
        for port in list_ports.comports():
            print(f"{port.device}: {port.description}")
        return 0
    if not args.port:
        parser.error("--port is required (use --list-ports to find it)")
    if args.baud <= 0 or not 0 < args.timeout < float("inf") or (args.random is not None and args.random <= 0):
        parser.error("baud, timeout and random count must be positive")
    rng = random.Random(args.seed)
    failures = 0
    try:
        with serial.Serial(args.port, args.baud, timeout=args.timeout,
                           write_timeout=args.timeout, bytesize=serial.EIGHTBITS,
                           parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE,
                           xonxoff=False, rtscts=False, dsrdtr=False) as port:
            port.reset_input_buffer()
            for case in range(args.random or 1):
                if args.random is None:
                    a, b = read_matrix("A"), read_matrix("B")
                else:
                    a, b = ([[rng.randint(0, 15) for _ in range(4)] for _ in range(4)]
                            for _ in range(2))
                expected = multiply(a, b)
                print(f"\nCase {case + 1}")
                show_matrix("A", a)
                show_matrix("B", b)
                actual = compute(port, a, b)
                show_matrix("Python A × B", expected)
                show_matrix("FPGA A × B", actual)
                mismatches = [(r, c) for r in range(4) for c in range(4)
                              if actual[r][c] != expected[r][c]]
                print("FAIL" if mismatches else "PASS")
                failures += bool(mismatches)
                for r, c in mismatches:
                    print(f"  C[{r + 1},{c + 1}]: expected {expected[r][c]}, received {actual[r][c]}")
    except (OSError, serial.SerialException, ValueError, EOFError) as error:
        print(f"Error: {error}\nReset the FPGA before retrying an interrupted transaction.", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("\nInterrupted. Reset the FPGA before retrying.", file=sys.stderr)
        return 130
    print(f"\n{(args.random or 1) - failures}/{args.random or 1} cases passed.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
