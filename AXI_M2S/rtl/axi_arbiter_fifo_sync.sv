`timescale 1ns/1ps

module axi_arbiter_fifo_sync
     // synopsys translate_off
     `protect
     // synopsys translate_on
     #(parameter FDW =32,  // fifof data width
                 FAW =5,  // num of entries in 2 to the power FAW
                 FULN=4)  // lookahead-full
(
       input   logic           rstn// asynchronous reset (active low)
     , input   logic           clr // synchronous reset (active high)
     , input   logic           clk

     , output  logic           wr_rdy
     , input   logic           wr_vld
     , input   logic [FDW-1:0] wr_din

     , input   logic           rd_rdy
     , output  logic           rd_vld
     , output  logic [FDW-1:0] rd_dout

     , output  logic           full
     , output  logic           empty

     , output  logic           fullN  // lookahead full
     , output  logic           emptyN // lookahead empty

     , output  logic  [FAW:0]   item_cnt // num of elements in the FIFO to be read
     , output  logic [FAW:0]   room_cnt // num of rooms in the FIFO to be written
);


    localparam FDT  = 1<<FAW;

    logic   [FAW:0]   fifo_head; // where data to be read
    logic   [FAW:0]   fifo_tail; // where data to be written

    logic   [FAW:0]   next_tail;
    logic   [FAW:0]   next_head;
    logic   [FAW-1:0] read_addr = (rd_vld&rd_rdy) ? next_head[FAW-1:0] : fifo_head[FAW-1:0];

        //---------------------------------------------------
        // accept input
        // push data item into the entry pointed by fifo_tail
        //
        always_ff @(posedge clk or negedge rstn) begin
            if (rstn==1'b0) begin
                fifo_tail <= 0;
                next_tail <= 1;
            end else if (clr) begin
                fifo_tail <= 0;
                next_tail <= 1;
            end else begin
                if (!full && wr_vld) begin
                    fifo_tail <= next_tail;
                    next_tail <= next_tail + 1;
                end 
            end
        end
        //---------------------------------------------------
        //---------------------------------------------------
        // provide output
        // pop data item from the entry pointed by fifo_head
        //
        always @(posedge clk or negedge rstn) begin
            if (rstn==1'b0) begin
                fifo_head <= 0;
                next_head <= 1;
            end else if (clr) begin
                fifo_head <= 0;
                next_head <= 1;
            end else begin
                if (!empty && rd_rdy) begin
                    fifo_head <= next_head;
                    next_head <= next_head + 1;
                end
            end
        end
        //---------------------------------------------------
        //---------------------------------------------------
        // how many items in the FIFO
        //
        assign  room_cnt = FDT-item_cnt;
        always_ff @(posedge clk or negedge rstn) begin
            if (rstn==1'b0) begin
                item_cnt <= 0;
            end else if (clr) begin
                item_cnt <= 0;
            end else begin
                if (wr_vld&&!full&&(!rd_rdy||(rd_rdy&&empty))) begin
                    item_cnt <= item_cnt + 1;
                end else
                if (rd_rdy&&!empty&&(!wr_vld||(wr_vld&&full))) begin
                    item_cnt <= item_cnt - 1;
                end
            end
        end
        
        //---------------------------------------------------
        //---------------------------------------------------
        assign rd_vld = ~empty;
        assign wr_rdy = ~full;
        assign empty  = (fifo_head == fifo_tail);
        assign full   = (item_cnt>=FDT);
        //---------------------------------------------------
        assign fullN  = (item_cnt>=(FDT-FULN));
        assign emptyN = (item_cnt<=FULN);
        //---------------------------------------------------
        //---------------------------------------------------
        logic [FDW-1:0] Mem [0:FDT-1];
        assign rd_dout  = Mem[fifo_head[FAW-1:0]];
        always_ff @(posedge clk) begin
            if (!full && wr_vld) begin
                Mem[fifo_tail[FAW-1:0]] <= wr_din;
            end
        end
        //---------------------------------------------------

endmodule