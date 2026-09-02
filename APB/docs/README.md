# APB Memory Slave

A simple **AMBA APB memory-mapped slave** implemented in SystemVerilog.

This project is intended as a learning exercise for understanding the **APB protocol**, FSM-based protocol control, and memory read/write operations.

## 1. Project Overview

The `APB_Memory` module implements a simple APB slave containing:

* 32 memory entries by default
* 32-bit data width
* APB-style `SETUP` and `ACCESS` phases
* Read operation
* Write operation
* `PREADY` response
* `PSLVERR` response signal
* Synchronous memory write
* Combinational memory read

Default configuration:

```text
DATA_WIDTH   = 32 bits
MEMORY_DEPTH = 32 entries
ADDR_WIDTH   = clog2(32) = 5 bits
```

Therefore, the memory contains:

```text
mem[0]  → 32 bits
mem[1]  → 32 bits
...
mem[31] → 32 bits
```

## 2. APB Transaction Flow

The slave uses three internal states:

```text
          PSEL=1
IDLE  ─────────────►  SETUP
                      │
                      │ PENABLE=1
                      ▼
                    ACCESS
                      │
                      │ PREADY=1
                      ▼
                     IDLE
```

### IDLE

No APB transfer is active.

```text
PSELX   = 0
PENABLE = 0
```

When:

```text
PSELX   = 1
PENABLE = 0
```

the FSM moves to `SETUP`.

### SETUP

The APB master has selected the slave and presents the address/control signals.

```text
PSELX   = 1
PENABLE = 0
```

When:

```text
PSELX   = 1
PENABLE = 1
```

the FSM moves to `ACCESS`.

### ACCESS

The actual transfer takes place.

```text
PSELX   = 1
PENABLE = 1
PREADY  = 1
```

The slave performs either a read or a write depending on `PWRITE`.

## 3. Read Operation

For a read:

```text
PWRITE = 0
```

The memory contents at `PADDR` are returned on `PRDATA`.

Example:

```text
PADDR  = 5
PWRITE = 0
```

If:

```text
mem[5] = 32'h1234_ABCD
```

then:

```text
PRDATA = 32'h1234_ABCD
```

The current implementation performs the read combinationally during the `ACCESS` state.

## 4. Write Operation

For a write:

```text
PWRITE = 1
```

The memory is updated on the rising edge of `PCLK`.

Example:

```text
PADDR  = 5
PWDATA = 32'h1234_ABCD
PWRITE = 1
```

The result is:

```systemverilog
mem[5] <= 32'h1234_ABCD;
```

## 5. Addressing

In this educational implementation, `PADDR` directly represents the memory entry index.

For the default configuration:

```text
PADDR[4:0]
```

is sufficient to select one of the 32 entries.

Therefore:

```text
PADDR = 0  → mem[0]
PADDR = 1  → mem[1]
PADDR = 2  → mem[2]
...
PADDR = 31 → mem[31]
```

This is a simplified model for learning APB.

It does **not** yet model a conventional byte-addressed 32-bit APB memory map such as:

```text
0x00 → word 0
0x04 → word 1
0x08 → word 2
...
```

## 6. Module Interface

```systemverilog
module APB_Memory #(
    parameter DATA_WIDTH   = 32,
    parameter MEMORY_DEPTH = 32,
    localparam ADDR_WIDTH = $clog2(MEMORY_DEPTH)
) (
    input  logic                  Pclk,
    input  logic                  Prst,
    input  logic [ADDR_WIDTH-1:0] Paddr,
    input  logic                  Pselx,
    input  logic                  Penable,
    input  logic                  Pwrite,
    input  logic [DATA_WIDTH-1:0] Pwdata,

    output logic                  Pready,
    output logic                  Pslverr,
    output logic [DATA_WIDTH-1:0] Prdata,
    output logic [DATA_WIDTH-1:0] temp
);
```

### Signals

| Signal    | Direction | Description                             |
| --------- | --------- | --------------------------------------- |
| `Pclk`    | Input     | APB clock                               |
| `Prst`    | Input     | Active-low reset                        |
| `Paddr`   | Input     | Memory address/index                    |
| `Pselx`   | Input     | Slave select                            |
| `Penable` | Input     | APB enable signal                       |
| `Pwrite`  | Input     | `1` = write, `0` = read                 |
| `Pwdata`  | Input     | Write data                              |
| `Pready`  | Output    | Transfer ready                          |
| `Pslverr` | Output    | Transfer error indicator                |
| `Prdata`  | Output    | Read data                               |
| `temp`    | Output    | Additional read-data observation signal |

## 7. Testbench

The project includes a simple testbench that performs:

```text
RESET
  ↓
WRITE
  ↓
READ
  ↓
CHECK RESULT
```

The main test writes:

```text
Address = 5
Data    = 32'h1234_ABCD
```

and then reads address `5`.

Expected result:

```text
Read data = 32'h1234_ABCD
```

The testbench reports:

```text
PASS: Read data matches write data
```

when the transaction is successful.

## 8. Directory Structure

Recommended project structure:

```text
APB/
├── rtl/
│   └── APB_Memory.sv
│
├── tb/
│   └── APB_Memory_tb.sv
│
├── sim/
│
└── README.md
```

## 9. Linting with Verilator

Run:

```bash
verilator --lint-only --Wall rtl/APB_Memory.sv
```

To lint both RTL and testbench:

```bash
verilator --lint-only --Wall rtl/APB_Memory.sv tb/APB_Memory_tb.sv
```

## 10. Simulation with Questa

Compile the RTL:

```bash
vlog rtl/APB_Memory.sv
```

Compile the testbench:

```bash
vlog tb/APB_Memory_tb.sv
```

Run the simulation:

```bash
vsim work.APB_Memory_tb
```

Run all simulation time:

```tcl
run -all
```

## 11. Useful Questa `run.do`

A simple `run.do` file:

```tcl
vlog rtl/APB_Memory.sv
vlog tb/APB_Memory_tb.sv

vsim work.APB_Memory_tb

add wave -divider "APB Signals"

add wave sim:/APB_Memory_tb/Pclk
add wave sim:/APB_Memory_tb/Prst
add wave sim:/APB_Memory_tb/Paddr
add wave sim:/APB_Memory_tb/Pselx
add wave sim:/APB_Memory_tb/Penable
add wave sim:/APB_Memory_tb/Pwrite
add wave sim:/APB_Memory_tb/Pwdata

add wave -divider "APB Outputs"

add wave sim:/APB_Memory_tb/Pready
add wave sim:/APB_Memory_tb/Pslverr
add wave sim:/APB_Memory_tb/Prdata
add wave sim:/APB_Memory_tb/temp

add wave -divider "FSM"

add wave sim:/APB_Memory_tb/dut/PRESENT_STATE
add wave sim:/APB_Memory_tb/dut/NEXT_STATE

add wave -divider "Memory"

add wave sim:/APB_Memory_tb/dut/mem

run -all
```

Run it from Questa:

```bash
vsim -do run.do
```

## 12. Expected APB Write

Example write transaction:

```text
SETUP:
    PSELX    = 1
    PENABLE  = 0
    PWRITE   = 1
    PADDR    = 5
    PWDATA   = 1234_ABCD

ACCESS:
    PSELX    = 1
    PENABLE  = 1
    PWRITE   = 1
    PREADY   = 1
```

Result:

```text
mem[5] = 32'h1234_ABCD
```

## 13. Expected APB Read

Example read transaction:

```text
SETUP:
    PSELX    = 1
    PENABLE  = 0
    PWRITE   = 0
    PADDR    = 5

ACCESS:
    PSELX    = 1
    PENABLE  = 1
    PWRITE   = 0
    PREADY   = 1
```

Result:

```text
PRDATA = 32'h1234_ABCD
```

## 14. Current Limitations

This implementation is intentionally simple.

It currently does not include:

* APB address decoding
* Byte strobes / `PSTRB`
* Wait states
* Multiple APB slaves
* Real byte-addressed memory mapping
* Invalid-address checking
* Complex `PSLVERR` generation
* Back-to-back transaction optimization
* APB4-specific features

These can be added later as the APB project becomes more advanced.

## 15. Learning Goals

This project is designed to practice:

```text
SystemVerilog
     ↓
FSM design
     ↓
APB SETUP / ACCESS phases
     ↓
Read / Write control
     ↓
Memory implementation
     ↓
Verilator lint
     ↓
Questa simulation
     ↓
Waveform debugging
```

The next natural extension is an **APB interconnect with multiple APB slaves**, allowing the same APB master to access peripherals such as RAM, GPIO, UART, or a timer.
