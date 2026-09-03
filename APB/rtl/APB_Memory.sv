module APB_Memory #(
    parameter DATA_WIDTH = 32, MEMORY_DEPTH = 32,
    localparam ADDR_WIDTH = $clog2(MEMORY_DEPTH)
) (
    input logic PCLK,
    input logic PRESET,
    input logic [ADDR_WIDTH-1:0] PADDR, //MEMory only has 32 entries
    input logic PSEL, 
    input logic PENABLE,
    input logic PWRITE,
    input logic [DATA_WIDTH-1:0] PWDATA,
    
    output logic PREADY,
    output logic PSLAVERR,
    output logic [DATA_WIDTH-1:0] PRDATA,
    output logic [DATA_WIDTH-1:0] TEMP
);
    

    logic [DATA_WIDTH - 1 : 0] MEM [0 : MEMORY_DEPTH - 1];

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        SETUP   = 2'b01,
        ACCESS  = 2'b10
    } state_t;

state_t PRESENT_STATE, NEXT_STATE;

always_ff @(posedge PCLK or negedge PREET) begin
    if(!PREET) begin
        PRESENT_STATE <= IDLE;
    end else begin
        PRESENT_STATE <= NEXT_STATE;
    end
end

always_comb  begin
    NEXT_STATE = PRESENT_STATE;

    PREADY  = 1'b0;
    PSLAVERR = 1'b0;
    PRDATA  = '0;
    TEMP = '0;

    case (PRESENT_STATE)
        
        IDLE: begin
            if(PSEL && !PENABLE) begin //PSEL = 1 and PENABLE = 0
                NEXT_STATE = SETUP;
            end 
        end

        SETUP: begin
            if(PSEL && PENABLE) begin //PSEL = 1 and PENABLE = 1
                NEXT_STATE = ACCESS;

            end else begin
                NEXT_STATE = IDLE;
            end
        end

        ACCESS: begin
            PREADY = 1;
            if(!PWRITE) begin // READ
                PRDATA = MEM[PADDR];
                TEMP = MEM[PADDR];
                PSLAVERR = 0;
            end  
            if(!PENABLE || !PSEL) begin
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

    always_ff @(posedge PCLK or negedge PREET) begin
            if (PRESENT_STATE == ACCESS &&
            PSEL &&
            PENABLE &&
            PWRITE &&
            PREADY) begin
                MEM[PADDR] <= PWDATA;
            end
    end
    
endmodule
