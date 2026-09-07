module AHB2AHB_master#(
    parameter FIFO_AW = 5
)(
    //--------------------------------------------------------//
    //AHB master port
    input   logic           HRESETn,
    input   logic           HCLK,
    output  logic           HBUSREQ,
    input   logic           HGRANT,
    output  logic [31:0]    HADDR,
    output  logic [1:0]     HTRANS,
    output  logic           HWRITE,
    output  logic [2:0]     HSIZE, 
    output  logic [2:0]     HBURST,
    output  logic [31:0]    HWDATA,
    input   logic [31:0]    HRDATA,
    input   logic [1:0]     HRESP,
    input   logic           HREADY,

    //--------------------------------------------------------//
    // FIFO forward port: address related
    output  logic               frd_clk,
    output  logic               frd_rdy,
    input   logic               frd_vld,
    input   logic [31:0]        frd_dat,
    input   logic               frd_empty,
    input   logic [FIFO_AW:0]   frd_cnt,  

    //--------------------------------------------------------//
    // FIFO backward port: data related
    output  logic               bwr_clk,
    input   logic               bwr_rdy,
    output  logic               bwr_vld,
    output  logic [31:0]        bwr_dat,
    input   logic               bwr_full,
    input   logic [FIFO_AW:0]   bwr_cnt 
);
    
endmodule