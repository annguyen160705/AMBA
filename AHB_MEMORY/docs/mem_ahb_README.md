```systemverilog
input  logic        HRESETn,     // Active-low reset
input  logic        HCLK,        // AHB clock
input  logic        HSEL,        // Slave select
input  logic [31:0] HADDR,       // Address of the transfer
input  logic [1:0]  HTRANS,      // Transfer type: IDLE, BUSY, NONSEQ, SEQ
input  logic        HWRITE,      // Transfer direction: 1 = write, 0 = read
input  logic [2:0]  HSIZE,       // Transfer size: byte, halfword, word
input  logic [2:0]  HBURST,      // Burst type
input  logic [31:0] HWDATA,      // Write data
output logic [31:0] HRDATA,      // Read data
output logic [1:0]  HRESP,       // Transfer response: OKAY or ERROR
input  logic        HREADYin,    // Indicates previous transfer is complete
output logic        HREADYout    // Indicates current transfer is complete
```

```systemverilog
assign HRESP = 2'b00; // Always return OKAY response; example: 2'b00 = successful transfer

localparam ADD_WIDTH = $clog2(SIZE_IN_BYTES); // Address width; example: 1024 bytes -> ADD_WIDTH = 10

localparam NUM_WORDS = SIZE_IN_BYTES/4; // Number of 32-bit words; example: 1024 bytes / 4 = 256 words

logic [31:0] mem [0: NUM_WORDS-1]; // 32-bit memory array; example: mem[0] = first 32-bit word, mem[255] = last word

logic [ADD_WIDTH-1:0] T_ADDR, T_ADDRw; // Current and delayed address; example: T_ADDR = 0x20 -> T_ADDRw holds it one cycle later

logic [31:0] T_DATA; // Temporary write data; example: T_DATA = 0x12345678

logic [3:0] T_BE, T_BE_D; // Byte enables and delayed byte enables; example: 4'b0011 = enable lower 2 bytes

logic T_WR, T_WR_D; // Write control and delayed write control; example: T_WR = 1 -> current transfer is a write

logic T_ENABLED = HSEL && HREADYin && HTRANS[1]; // Transfer is valid; example: HSEL=1, HREADYin=1, HTRANS=2'b10 -> T_ENABLED=1
```

```systemverilog
always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA    <= ~32'h0; // // Resets read data output register to all ones (32'hFFFFFFFF)
            T_ADDR    <= ~'h0;   // // Resets internal address capture register to all ones
            T_ADDRw   <= ~'h0;   // // Resets delayed write address register to all ones
            T_DATA    <= ~32'h0; // // Resets temporary data assembly register to all ones
            T_BE      <= 4'h0;   // // Clears current byte-enable signals to 4'b0000
            T_WR      <= 1'b0;   // // Clears current write-enable command flag to 0
            T_BE_D    <= 4'h0;   // // Clears delayed byte-enable signals to 4'b0000
            T_WR_D    <= 1'b0;   // // Clears delayed write-enable flag to 0
        end else begin
            if(T_ENABLED) begin
                T_ADDR <= HADDR[ADD_WIDTH-1:0];        // // Captures the active AHB address bits for this transfer
                T_BE    <= byte_enable(HADDR[1:0], HSIZE); // // Decodes byte enables based on transfer size and offset
                T_WR    <= HWRITE;                     // // Samples whether the current transfer is a write (1) or read (0)
                HRDATA  <= mem[HADDR[ADD_WIDTH-1:2]];  // // Performs a synchronous read lookup from the memory array
            end else begin
                T_BE    <= 4'h0;                       // // Disables byte lanes if the current transfer is unselected/idle
                T_WR    <= 1'b0;                       // // Disables write operation if unselected
            end
            if  (T_WR) begin
                // // Implements a byte-lane merge (Read-Modify-Write) using active byte enables
                T_DATA [7:0]   <= (T_BE[0]) ? HWDATA[7:0]   : HRDATA[7:0];   // // Byte lane 0 update
                T_DATA [15:8]  <= (T_BE[1]) ? HWDATA[15:8]  : HRDATA[15:8];  // // Byte lane 1 update
                T_DATA [23:16] <= (T_BE[2]) ? HWDATA[23:16] : HRDATA[23:16]; // // Byte lane 2 update
                T_DATA [31:24] <= (T_BE[3]) ? HWDATA[31:24] : HRDATA[31:24]; // // Byte lane 3 update

                T_BE_D  <= T_BE;  // // Pipelines byte enables forward to match the data phase cycle
                T_WR_D  <= T_WR;  // // Pipelines the write flag forward to match the data phase cycle
            end else begin
                T_BE_D  <= 4'h0;  // // Resets delayed byte enables when not writing
                T_WR_D  <= 1'b0;  // // Resets delayed write flag when not writing
            end
            if  (T_WR_D) begin
                mem[T_ADDRw[ADD_WIDTH-1:2]] <= T_DATA; // // Commits the assembled 32-bit word into the target memory index
            end
            T_ADDRw <= T_ADDR;    // // Pipelines the address register to synchronize with the delayed write phase
        end
    end
```

```systemverilog
function automatic logic [3:0] byte_enable(
    input logic [1:0] add,        // Lower 2 address bits; example: 2'b01 means byte offset 1
    input logic [2:0] size        // AHB transfer size; example: 3'b000 = byte, 3'b001 = halfword, 3'b010 = word
);
    logic [3:0] be;               // Byte-enable result; bit 0->byte 0, bit 3->byte 3

    case ({size,add})             // Combine HSIZE and address offset; example: 000_01 = byte transfer at address offset 1

        `ifdef ENDIAN_BIG

            5'b010_00: be = 4'b1111;    // Word, address aligned to 0; example: 0x100 -> use all 4 bytes
            5'b001_00: be = 4'b1100;    // Halfword at offset 0; example: 0x100 -> use bytes 2 and 3
            5'b001_10: be = 4'b0011;    // Halfword at offset 2; example: 0x102 -> use bytes 0 and 1
            5'b000_00: be = 4'b1000;    // Byte at offset 0; example: 0x100
            5'b000_01: be = 4'b0100;    // Byte at offset 1; example: 0x101
            5'b000_10: be = 4'b0010;    // Byte at offset 2; example: 0x102
            5'b000_11: be = 4'b0001;    // Byte at offset 3; example: 0x103

        `else // little-endian -- default

            5'b010_00: be = 4'b1111;    // Word, address aligned to 0; example: 0x100 -> use all 4 bytes
            5'b001_00: be = 4'b0011;    // Halfword at offset 0; example: 0x100 -> use bytes 0 and 1
            5'b001_10: be = 4'b1100;    // Halfword at offset 2; example: 0x102 -> use bytes 2 and 3
            5'b000_00: be = 4'b0001;    // Byte at offset 0; example: 0x100 -> use byte 0
            5'b000_01: be = 4'b0010;    // Byte at offset 1; example: 0x101 -> use byte 1
            5'b000_10: be = 4'b0100;    // Byte at offset 2; example: 0x102 -> use byte 2
            5'b000_11: be = 4'b1000;    // Byte at offset 3; example: 0x103 -> use byte 3

        `endif

        default: begin
            be = 4'b0;                 // Invalid alignment/size combination; example: unaligned halfword -> no bytes enabled

            `ifdef RIGOR
                // synopsys translate_off
                $display($time,, "%m ERROR: undefined combination of HSIZE(%x) and HADDR[1:0](%x)",
                         size, add);   // Print an error during simulation
                // synopsys translate_on
            `endif
        end

    endcase

    byte_enable = be;                 // Return the calculated byte-enable mask
endfunction
```

# Example
```
CPU
 │
 │ HADDR = 0x25
 │ HSIZE = BYTE
 │ HWRITE = 1
 │ HWDATA = 0x0000BBAA
 ▼
T_ENABLED = 1
 │
 ▼
T_ADDR = 0x25
T_BE   = 0010
T_WR   = 1
 │
 ▼
Read old word
mem[9] = 0x00000009
 │
 ▼
Merge bytes
old: 0x00000009
new: 0x0000BBAA
BE : 0b0010
 │
 ▼
T_DATA = 0x0000BB09
 │
 ▼
mem[9] = 0x0000BB09
```