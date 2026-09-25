module mem_axi_dpram_sync_core #(
    parameter WIDTH_AD = 8
) (
    input logic RESETn
    , input logic CLK
    , input logic [WIDTH_AD-1:0]    WADDR
    , input logic [7:0]             WDATA
    , input logic                   WEN
    , input logic [WIDTH_AD-1:0]    RADDR
    , input logic                   REN
    , output logic [7:0]            RDATA
);

    localparam DEPTH    = (1<<WIDTH_AD);

    logic [7:0] mem [0:DEPTH-1];

    //--------------------------------------------------------//
    // write case
    always_ff @(posedge CLK or negedge RESETn) begin
        if (RESETn == 1'b0) begin
        end else begin
            if (WEN==1'b1) begin
                mem[WADDR]  <= WDATA;
            end
        end
    end

    //--------------------------------------------------------//
    // read case
    always_ff @(posedge CLK or negedge RESETn) begin
        if (RESETn == 1'b0) begin
            RDATA <= 'h0;
        end else begin
            if (REN == 1'b1) begin
                if((WEN==1'b1) && (RADDR == WADDR)) begin
                    RDATA   <= WDATA;
                end else begin
                    RDATA   <= mem[RADDR];
                end
            end else begin
                RDATA   <= 'hX;
            end
        end
    end
endmodule