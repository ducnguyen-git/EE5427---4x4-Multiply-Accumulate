# FPGA matrix serial checker

Run from this directory using the existing uv project and PySerial dependency:

```sh
uv run main.py --list-ports
uv run main.py --port /dev/ttyUSB0
uv run main.py --port /dev/ttyUSB0 --random 10 --seed 42
```

On Windows use a port such as `COM3`. Without `--random`, enter four rows
for A followed by four rows for B. Separate values with spaces or commas.
Inputs are unsigned integers **0–15**; both matrices are **4×4**.
Each case prints A, B, the Python product, the FPGA product, PASS/FAIL, and
any mismatched cells (row and column numbers start at 1).
Exit codes: 0 = all passed, 1 = mismatch, 2 = communication/input error.

Program the FPGA with [`compute_unit`](../rtl/compute_unit.sv) and reset it
before starting. The older switch/LED `top_fpga_wrapper` does not implement
this protocol. Connect through the board's USB UART bridge or a compatible
logic-level USB UART adapter: host TX to FPGA RX, host RX to FPGA TX, common
ground. Match the programmed baud using `--baud` (default 9600, 8N1).
Close other serial monitors before opening the port.

The tool implements the [binary byte protocol](../README.md#byte-protocol):
load A then B in row order, compute, and read all 16 results as little-endian
10-bit values. It spaces transmitted bytes for the RX mailbox and waits five
character times after load and compute. No acknowledgment or serial status
query exists. `--timeout 2` controls each serial read/write timeout in seconds.
A timeout or interrupted load can leave the FPGA expecting payload bytes;
reset the FPGA before retrying. The script cannot reset it through this protocol.

Run the host tests (mocked serial, no hardware required):

```sh
uv run python -m unittest -v
```
