module priority_arbiter #(
    parameter DATA_WIDTH = 4
) (
    input logic clk,
    input logic arstn,
    input logic [DATA_WIDTH-1:0] REQ,
    output logic [DATA_WIDTH-1:0] GNT    
);

    integer i;

    
    always_ff @(posedge clk or negedge arstn) begin
        if(!arstn) begin
            GNT <= '0;
        end else begin 
            for (i = DATA_WIDTH - 1; i >= 0; i = i - 1) begin
                if (REQ[i]) begin
                    GNT <= '0;
                    GNT[i] <= REQ [i];
                    break;
                end
            end
            
        end
    end

    
endmodule



