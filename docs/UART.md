# Matrix UART protocol

Connect `MAC4x4_uart` to `MAC4x4` using `LOAD`, `START`, `A[63:0]`,
`B[63:0]`, `C[159:0]`, and `DONE`. Both modules share `clk` and `rst_n`.
`SELECT` has been removed. The default UART baud rate is 9600; configure
`CLK_FREQ` to the actual system clock. The clock divider requires at least
32 system clocks per UART bit with the default 16x RX oversampling.

## Request

Send exactly 16 bytes using 8N1 (8 data bits, no parity, one stop bit):

1. Eight bytes for A, most significant byte first.
2. Eight bytes for B, most significant byte first.

Each byte contains two unsigned 4-bit elements, high nibble first. Matrices
are row-major: A[63:60] is A[0,0], and A[3:0] is A[3,3]. B uses the same order.
The transport loads the matrices and issues START automatically.

## Response

The core supplies all sixteen 10-bit results together. Element i is
`C[159-10*i -: 10]`, where i = 4*row + column. On DONE the transport snapshots
the complete matrix. Subsequent changes to the core output cannot affect it.

The transport sends one uninterrupted 32-byte response in row-major order:
`C[0,0]`, `C[0,1]`, ..., `C[3,3]`. Each element uses two bytes:

- First byte: six zero bits followed by result bits [9:8].
- Second byte: result bits [7:0].

Within each byte, UART sends the least significant bit first. Adjacent bytes
have exactly one stop bit, with no additional idle gaps. The host does not
send element-selection commands. For example, an all-15 input pair produces
sixteen results of 900, transmitted as sixteen repetitions of `03 84`.

UART remains serial: the response occupies 320 bit periods, or approximately
33.33 ms at 9600 baud (2.78 ms at 115200 baud when the divider supports it).
The packet retains 16-bit result slots for host compatibility; the core bus
uses only the necessary 160 bits.

## Transaction and reset rules

Wait for the complete response before sending the next request. `busy` is
asserted after the first request byte and stays high through the final stop
bit. Bytes received during computation/transmission are discarded. There is
one response buffer; this transport does not queue transactions.

The Nexys A7 `top_fpga_wrapper` exposes only CLK100MHZ, UART_RXD, and UART_TXD.
It generates reset automatically during the first four clock cycles after FPGA
configuration; there are no buttons, switches, displays, or external reset port.
After a lost packet boundary, reconfigure the FPGA to restart the board transport.
Disable hardware flow control in the host serial application.

A framing error or RX overrun discards a partial request. Reset aborts partial
requests, in-flight computations, and responses, returns TX high, and clears
the pipeline. There is no packet header, checksum, or partial-packet timeout;
after an interrupted transaction, reset before retrying if alignment is lost.
