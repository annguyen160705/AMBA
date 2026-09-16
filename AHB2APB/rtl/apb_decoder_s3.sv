module apb_decoder_s3 #(
    parameter P_NUM         = 3,
    parameter P_ADDR_START1 = 16'hC000, P_ADDR_SIZE1  = 16'h0001,
    parameter P_ADDR_START2 = 16'hC010, P_ADDR_SIZE2  = 16'h0001,
    parameter P_ADDR_START3 = 16'hC020, P_ADDR_SIZE3  = 16'h0001
) (
      input  logic        PSELin
    , input  logic [31:0] PADDR
    , output logic        PSELout1
    , output logic        PSELout2
    , output logic        PSELout3
);

    // END addresses evaluate to:
    // P_ADDR_END1 = 16'hC000 + 16'h0001 - 1 = 16'hC000
    // P_ADDR_END2 = 16'hC010 + 16'h0001 - 1 = 16'hC010
    // P_ADDR_END3 = 16'hC020 + 16'h0001 - 1 = 16'hC020
    localparam P_ADDR_END1 = P_ADDR_START1 + P_ADDR_SIZE1 - 1;
    localparam P_ADDR_END2 = P_ADDR_START2 + P_ADDR_SIZE2 - 1;
    localparam P_ADDR_END3 = P_ADDR_START3 + P_ADDR_SIZE3 - 1;
    
    logic [15:0] tpaddr;
    assign tpaddr = PADDR[31:16]; // Extracts the top 16 bits of the 32-bit address

    always_comb begin
        // Default assignments (Prevents combinational latches if no conditions are met)
        PSELout1 = 1'b0;
        PSELout2 = 1'b0;
        PSELout3 = 1'b0;

        if (P_NUM > 0 && tpaddr >= P_ADDR_START1 && tpaddr <= P_ADDR_END1) begin
            PSELout1 = PSELin;
        end
        if (P_NUM > 1 && tpaddr >= P_ADDR_START2 && tpaddr <= P_ADDR_END2) begin
            PSELout2 = PSELin;
        end
        if (P_NUM > 2 && tpaddr >= P_ADDR_START3 && tpaddr <= P_ADDR_END3) begin
            PSELout3 = PSELin;
        end
    end

endmodule