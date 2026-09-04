module AHB_master(
    //--------------------------------------------------------//
    //Global signals
    input logic HRESETn,
    input logic HCLK,

    //--------------------------------------------------------//
    //Transfer response
    input logic HREADY,
    input logic HRESP,
    
    //--------------------------------------------------------//
    //Data
    input logic [31:0] HRDATA,

    //--------------------------------------------------------//
    // Address control
    output logic [31:0] HADDR,
    output logic HWRITE,
    output logic [2:0] HSIZE,
    output logic [2:0] HBURST,
    output logic [3:0] HPROT,
    output logic [1:0] HTRANS,
    output logic HMASTLOCK,

    //--------------------------------------------------------//
    //Data
    output logic [31:0] HWDATA
);


    typedef struct packed {
        logic [7:0] mem0;
        logic [7:0] mem1;
        logic [7:0] mem2;
        logic [7:0] mem3;
    } mem_t;

    mem_t MEMMORY,MEMORY_OUT;

      



    
endmodule