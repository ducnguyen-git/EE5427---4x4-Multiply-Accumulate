#!/usr/bin/env python3
"""
Python Golden Reference Model & Test Vector Generator
Project: EE5427 - 4-element 4-bit Multiply-Accumulate (MAC) Unit
"""

import random

def mac_golden(vec_a: int, vec_b: int) -> int:
    """
    Computes dot-product of two 16-bit packed vectors:
    vec_a = {A3, A2, A1, A0}
    vec_b = {B3, B2, B1, B0}
    C = A0*B0 + A1*B1 + A2*B2 + A3*B3
    """
    a = [(vec_a >> (4 * i)) & 0xF for i in range(4)]
    b = [(vec_b >> (4 * i)) & 0xF for i in range(4)]
    products = [a[i] * b[i] for i in range(4)]
    return sum(products)

def generate_vectors(num_samples: int = 50, output_file: str = "test_vectors.hex"):
    with open(output_file, "w") as f:
        # Corner cases
        test_pairs = [
            (0x0000, 0x0000),
            (0x1111, 0x1111),
            (0xFFFF, 0xFFFF),
            (0x4321, 0x1234),
            (0xA0B0, 0x0C0D),
        ]
        # Random tests
        for _ in range(num_samples - len(test_pairs)):
            test_pairs.append((random.randint(0, 0xFFFF), random.randint(0, 0xFFFF)))

        for idx, (a, b) in enumerate(test_pairs):
            expected = mac_golden(a, b)
            f.write(f"{a:04X} {b:04X} {expected:03X}\n")

    print(f"Generated {len(test_pairs)} test vectors in '{output_file}'.")

if __name__ == "__main__":
    generate_vectors()
