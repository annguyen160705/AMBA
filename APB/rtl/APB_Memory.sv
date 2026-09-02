module APB_Memory #(
    parameter DATA_WIDTH = 32, MEMORY_DEPTH = 32,
    localparam ADDR_WIDTH = $clog2(MEMORY_DEPTH)
) (
    input logic Pclk,
    input logic Prst,
    input logic [ADDR_WIDTH-1:0] Paddr, //memory only has 32 entries
    input logic Pselx, 
    input logic Penable,
    input logic Pwrite,
    input logic [DATA_WIDTH-1:0] Pwdata,
    
    output logic Pready,
    output logic Pslverr,
    output logic [DATA_WIDTH-1:0] Prdata,
    output logic [DATA_WIDTH-1:0] temp
);
    

    logic [DATA_WIDTH - 1 : 0] mem [0 : MEMORY_DEPTH - 1];

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        SETUP   = 2'b01,
        ACCESS  = 2'b10
    } state_t;

state_t PRESENT_STATE, NEXT_STATE;

always_ff @(posedge Pclk or negedge Prst) begin
    if(!Prst) begin
        PRESENT_STATE <= IDLE;
    end else begin
        PRESENT_STATE <= NEXT_STATE;
    end
end

always_comb  begin
    NEXT_STATE = PRESENT_STATE;

    Pready  = 1'b0;
    Pslverr = 1'b0;
    Prdata  = '0;
    temp = '0;

    case (PRESENT_STATE)
        
        IDLE: begin
            if(Pselx && !Penable) begin //Pselx = 1 and Penable = 0
                NEXT_STATE = SETUP;
            end 
        end

        SETUP: begin
            if(Pselx && Penable) begin //Pselx = 1 and Penable = 1
                NEXT_STATE = ACCESS;

            end else begin
                NEXT_STATE = IDLE;
            end
        end

        ACCESS: begin
            Pready = 1;
            if(!Pwrite) begin // READ
                Prdata = mem[Paddr];
                temp = mem[Paddr];
                Pslverr = 0;
            end  
            if(!Penable || !Pselx) begin
                NEXT_STATE = IDLE;
                
            end
        end

        default: begin
            NEXT_STATE = IDLE;
        end
    endcase


end    

    //READ
    always_comb begin

    end

    always_ff @(posedge Pclk or negedge Prst) begin
            if (PRESENT_STATE == ACCESS &&
            Pselx &&
            Penable &&
            Pwrite &&
            Pready) begin
                mem[Paddr] <= Pwdata;
            end
    end
    
endmodule
