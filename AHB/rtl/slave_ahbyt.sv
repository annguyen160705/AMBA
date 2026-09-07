module slave_ahbyt(
    input HCLK,
    input HRESET,
    input logic [31:0] HADDR,
    input logic HWRITE,
    input logic [2:0] HSIZE, 
    input logic [2:0] HBURST, 
    input logic [1:0] HTRANS, 
    input logic [31:0] HWDATA,

    output logic HREADY,
    output logic  HRESP,
    output [31:0] HRDATA 
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        SAMPLE_STATE = 2'b01,
        WRITE_STATE = 2'b10,
        WRITE_STATE_READY = 2'b11
    } state_t;

    state_t present_state,next_state;

    logic [1:0] htrans_internal;
    logic hwrite_internal;
    logic [31:0] addr_internal;

    always_ff @(posedge HCLK) begin
        if (HRESET) begin
            present_state <= IDLE;
        end else begin
            present_state <= next_state;
        end
    end

    always_comb begin
        begin
            case (present_state)
                
                IDLE: begin
                    HREADY = 1;
                    next_state = SAMPLE_STATE;
                end

                SAMPLE_STATE: begin
                    htrans_internal = HTRANS;
                    hwrite_internal = HWRITE;
                    addr_internal = HADDR;

                    if(htrans_internal == 2'b10 || htrans_internal == 2'b11) begin
                        if(hwrite_internal) next_state = WRITE_STATE;
                    end

                end

                WRITE_STATE: begin
                    HRDATA = HWDATA;

                    if(htrans_internal == 2'b00) begin
                        next_state = IDLE;
                    end

                end

                default: begin
                    next_state = IDLE;
                end
            endcase
        end
    end

    
endmodule