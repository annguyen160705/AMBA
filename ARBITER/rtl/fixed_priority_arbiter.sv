module fixed_priority_arbiter(
    input logic clk,
    input logic rst_n,
    input logic [3:0] REQ,
    output logic [3:0] GNT
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            GNT <= 4'h0;
        end else begin
            case (REQ)
                
                4'h8 : GNT <=  4'h8;
                4'h4 : GNT <=  4'h4;
                4'h2 : GNT <=  4'h2;
                4'h1 : GNT <=  4'h1;
                default : GNT <= 4'h0;
                
            endcase
        end
    end

    
endmodule