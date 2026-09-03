`timescale 1ns/1ns

`ifdef AMBA4
`ifndef AMBA3
$error("AMBA3 must be defined when AMBA4 is defined");
`endif
`endif

module mem_apb #(
    parameter SIZE_IN_BYTES = 1024, DELAY = 0
) (
    input logic PRESETn,
    input logic PCLK,
    input logic PSEL,
    /* verilator lint_off UNUSEDSIGNAL */
    input logic [31:0] PADDR, 
    /*You must keep the full 32-bit port to maintain plug-and-play compatibility with the standard AMBA bus, 
    knowing that hardware synthesis tools will automatically delete the unused wires so no actual silicon is wasted.*/
    input logic PENABLE,
    input logic PWRITE,
    input logic [31:0] PWDATA,
    output logic [31:0] PRDATA
    `ifdef AMBA3
    ,output logic PREADY
    ,output logic PSLVERR
    `endif
    `ifdef AMBA4
    ,input logic [2:0] PPROT
    ,input logic [3:0] PSTRB
    `endif 
);

//--------------------------------------------------------//
`ifndef AMBA3
/* verilator lint_off UNUSEDSIGNAL */
logic PREADY = 1'b1;

logic PSLVERR = 1'b0;
`endif // AMBA3

`ifndef AMBA4

logic [2:0] PPROT = 3'h0;

logic [3:0] PSTRB = 4'hF;
/* verilator lint_on UNUSEDSIGNAL */
`endif 

logic [7:0] mem0 [0: SIZE_IN_BYTES/4 - 1]; //each of those 256 slots holds 8 bits (1 byte)
logic [7:0] mem1 [0: SIZE_IN_BYTES/4 - 1];
logic [7:0] mem2 [0: SIZE_IN_BYTES/4 - 1];
logic [7:0] mem3 [0: SIZE_IN_BYTES/4 - 1];
    
localparam A_WIDTH = $clog2(SIZE_IN_BYTES);
logic [A_WIDTH-1:2] addr;
assign addr = PADDR[A_WIDTH-1:2];
/*Master sends Address 0 (Binary 0000). Drop bottom two bits → Row Index 0.

Master sends Address 4 (Binary 0100). Drop bottom two bits → Row Index 1.

Master sends Address 8 (Binary 1000). Drop bottom two bits → Row Index 2.*/
//--------------------------------------------------------//

logic [31:0] dcnt = 'h1; //delay counter

//--------------------------------------------------------//

typedef enum logic [1:0] {
    ST_IDLE    = 2'b00,
    ST_SETUP = 2'b01,
    ST_ACCESS = 2'b10
} state_t;

state_t CURRENT_STATE;


always_ff @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        PRDATA <= ~32'h0;
        PREADY <= 1'b1;
        PSLVERR <= 1'b0;
        dcnt <= 'h1;
        CURRENT_STATE <= ST_IDLE;
    end else begin
        PSLVERR <= 1'b0;
        case (CURRENT_STATE)
            ST_IDLE: begin
                // Wait for APB Setup Phase (PSEL high, PENABLE low)
                if (PSEL && !PENABLE) begin
                    if (DELAY == 0) begin
                        PREADY <= 1'b1;
                        CURRENT_STATE <= ST_ACCESS;
                    end else begin
                        PREADY <= 1'b0;
                        dcnt <= DELAY;
                        CURRENT_STATE <= ST_SETUP;
                    end

                    // Prefetch Read Data immediately
                    if (!PWRITE) begin
                        PRDATA[7:0]   <= mem0[addr];
                        PRDATA[15:8]  <= mem1[addr];
                        PRDATA[23:16] <= mem2[addr];
                        PRDATA[31:24] <= mem3[addr];
                    end
                end 
            end

            ST_SETUP: begin
                // Counting Wait States
                if (dcnt == 1) begin
                    PREADY <= 1'b1; // Drive ready high for the ST_ACCESS cycle
                    CURRENT_STATE <= ST_ACCESS;
                end else begin
                    dcnt <= dcnt - 1;
                end
            end

            ST_ACCESS: begin
                // Final cycle of APB Access Phase. Committing Write Data.
                if (PWRITE) begin
                    if (PSTRB[3]) mem3[addr] <= PWDATA[31:24];
                    if (PSTRB[2]) mem2[addr] <= PWDATA[23:16];
                    if (PSTRB[1]) mem1[addr] <= PWDATA[15:8];
                    if (PSTRB[0]) mem0[addr] <= PWDATA[7:0];
                end
                // Return to IDLE immediately. If the master starts a back-to-back 
                // transfer, ST_IDLE will catch the new setup phase on the next clock.
                CURRENT_STATE <= ST_IDLE;
            end
            
            default: begin
                CURRENT_STATE <= ST_IDLE;
            end
        endcase
    end
end

endmodule
