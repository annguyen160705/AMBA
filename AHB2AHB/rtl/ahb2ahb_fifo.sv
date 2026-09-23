module ahb2ahb_fifo #(
    parameter FDW   = 8, // fifo data width
    parameter FAW   = 4, // num of entries in 2 to the power FAW
    parameter FULN  = 4  // lookahead-full
) (
      input logic               rst // asynchronous reset (active high)
    , input logic               clr // synchronous reset (active high)
    , input logic               clk

    , output logic              wr_rdy
    , input logic               wr_vld
    , input logic [FDW-1:0]     wr_din

    , input logic               rd_rdy
    , output logic              rd_vld
    , output logic [FDW-1:0]    rd_dout
    
    , output logic              full
    , output logic              empty
    , output logic              fullN  // lookahead full: there are only N rooms in the FIFO
    , output logic              emptyN // lookahead empty: there are only N items in the FIFO

    , output logic  [FAW:0]     rd_cnt // num of elements in the FIFO to be read
    , output logic  [FAW:0]     wr_cnt // num of rooms in the FIFO to be written
);


localparam FDT = 1<<FAW;

logic [FAW:0] fifo_head = 0; // where data to be read
logic [FAW:0] fifo_tail = 0; // where data to be written
logic [FAW:0] next_tail = 0;
logic [FAW:0] next_head = 0;
logic [FAW-1:0] read_addr  ;

assign read_addr = (rd_vld&rd_rdy) ? next_head[FAW-1:0] : fifo_head[FAW-1:0];
    //--------------------------------------------------------//
    // accept input
    // push data item into the entry pointed by fifo_tail
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            fifo_tail <= 0;
            next_tail <= 1;
        end else if (clr) begin
            fifo_tail <= 0;
            next_tail <= 1;
        end else begin
            if(!full && wr_vld) begin
                fifo_tail   <= next_tail;
                next_tail   <= next_tail + 1;
            end
        end
    end
    //--------------------------------------------------------//
    // provide output
    // pop data item from the entry pointed by fifo_head
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            fifo_head <= 0;
            next_head <= 1;
        end else if (clr) begin
            fifo_head <= 0;
            next_head <= 1;
        end else begin
            if(!empty && rd_rdy) begin
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
    assign rd_dout  = Mem[fifo_head[FAW-1:0]];
    always @(posedge clk) begin
        if(!full && wr_vld) begin
            Mem[fifo_tail[FAW-1:0]] <= wr_din;
        end
    end
    
endmodule