module AHB2AHB_master#(
    parameter FIFO_AW = 5
)(
    
    input logic HRESETn,
    input logic HCLK,
    output logic HBUSREQ,
    input logic HGRANT,
    output logic [31:0] HADDR,
    output logic [1:0] HTRANS,
    output logic HWRITE,
    output logic [2:0] HSIZE, 
    output logic [2:0] HBURST,
    output logic [31:0] HWDATA,
    input logic [31:0] HRDATA,
    input logic [1:0] HRESP,
    input logic HREADY,


);
    
endmodule