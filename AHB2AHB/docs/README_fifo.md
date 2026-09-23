```systemverilog
module ahb2ahb_fifo #(
    parameter FDW   = 8, // fifo data width
    parameter FAW   = 4, // num of entries in 2 to the power FAW
    parameter FULN  = 4  // lookahead-full
) (
      input logic               rst 
    , input logic               clr 
    , input logic               clk

    , output logic              wr_rdy
    , input logic               wr_vld
    , input logic [FDW-1:0]     wr_din

    , input logic               rd_rdy
    , output logic              rd_vld
    , output logic [FDW-1:0]    rd_dout
    
    , output logic              full
    , output logic              empty
    , output logic              fullN  
    , output logic              emptyN 

    , output logic  [FAW:0]     rd_cnt 
    , output logic  [FAW:0]     wr_cnt 
);

localparam FDT = 1<<FAW;

// =========================================================================
// RING BUFFER ARCHITECTURE
// This FIFO does NOT shift data like a conveyor belt (15 -> 14 -> ... -> 0).
// Shifting data every clock cycle burns too much power. 
// Instead, the data stays perfectly still in the Memory Array.
// We only move the "pointers" (head and tail). Both start at 0 and COUNT UP.
// =========================================================================

logic [FAW:0] fifo_head = 0; // Read Pointer (Exit Gate): "Where is the oldest data?"
logic [FAW:0] fifo_tail = 0; // Write Pointer (Entrance Gate): "Where is the next empty space?"
logic [FAW:0] next_tail = 0;
logic [FAW:0] next_head = 0;
logic [FAW-1:0] read_addr  ;

assign read_addr = (rd_vld&rd_rdy) ? next_head[FAW-1:0] : fifo_head[FAW-1:0];
    
    //--------------------------------------------------------//
    // accept input (Pushing)
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            fifo_tail <= 0;
            next_tail <= 1;
        end else if (clr) begin
            fifo_tail <= 0;
            next_tail <= 1;
        end else begin
            if(!full && wr_vld) begin
                // [WRITING DATA]
                // We do not push data backwards from 15. 
                // If tail is 0, we write data to slot 0.
                // Then, tail moves to slot 1 (tail + 1). 
                // The tail always counts UP, chasing the head around the circle.
                fifo_tail   <= next_tail;
                next_tail   <= next_tail + 1;
            end
        end
    end
    
    //--------------------------------------------------------//
    // provide output (Popping)
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            fifo_head <= 0;
            next_head <= 1;
        end else if (clr) begin
            fifo_head <= 0;
            next_head <= 1;
        end else begin
            if(!empty && rd_rdy) begin
                // [READING DATA]
                // We do NOT pop from the tail (that's the newest data).
                // We read from the head (the oldest data).
                // When read is complete, the data in memory stays where it is.
                // We just move the head pointer forward (head + 1) to look at the 
                // next oldest piece of data in the next slot.
                fifo_head   <= next_head;
                next_head   <= next_head + 1;
            end
        end
    end
    
    //--------------------------------------------------------//
    // How many items in the FIFO
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            rd_cnt  <= 0;
        end else if (clr) begin
            rd_cnt  <= 0;
        end else begin
            if (wr_vld && !full && (!rd_rdy||(rd_rdy&&empty))) begin
                rd_cnt  <= rd_cnt + 1;
            end
            if (rd_rdy && !empty && (!wr_vld||(wr_vld&&full))) begin
                rd_cnt  <= rd_cnt - 1;
            end
        end
    end
    
    //--------------------------------------------------------//
    always_comb begin
        wr_cnt  = FDT-rd_cnt                ;
        empty   = (fifo_head == fifo_tail)  ;
        full    = (rd_cnt >= FDT)           ;
        rd_vld  = ~empty                    ;
        wr_rdy  = ~full                     ;
        fullN   = (wr_cnt <= FULN)          ;
        emptyN  = (rd_cnt <= FULN)          ;
    end

    logic [FDW-1:0] Mem [0:FDT-1]; 
    
    // The head pointer (currently pointing at the oldest data) connects 
    // directly to the output. As head counts up, the output automatically changes.
    assign rd_dout  = Mem[fifo_head[FAW-1:0]]; 
    
    always @(posedge clk) begin
        if(!full && wr_vld) begin
            Mem[fifo_tail[FAW-1:0]] <= wr_din;
        end
    end
    
endmodule
```