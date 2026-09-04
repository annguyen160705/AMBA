module AHB_slave(
    input logic HRESETn,
    input logic HCLK,
    input logic HSEL,
    input logic [31:0] HADDR,
    input logic HWRITE,
    input logic [2:0] HSIZE, 
    input logic [2:0] HBURST,
    input logic [3:0] HPROT, 
    input logic [1:0] HTRANS,
    input logic HMASTLOCK,
    input logic HREADY,
    input logic [31:0] HWDATA,
    
    output logic HREADYOUT 
    output logic [31:0] HRDATA,
    output logic [1:0] HRESP,
);

    assign HRDATA = 32'h0;

    typedef enum logic [1:0] {
        STH_IDLE    = 2'b00,
        STH_WRITE = 2'b01,
        STH_READ0 = 2'b10
    } AHB_Slave_FSM_state_t;

    AHB_Slave_FSM_state_t CURRENT_STATE;

    typedef enum logic [1:0] {
        HTRANS_IDLE    = 2'b00,
        HTRANS_BUSY = 2'b01,
        HTRANS_NONSEQ = 2'b10,
        HTRANS_SEQ = 2'b11
    } HTRANS_state_t;

    HTRANS_state_t HTRANSselect;
    assign HTRANSselect = HTRANS_state_t'(HTRANS);

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRESP <= '0;
            HREADYOUT <= '1;
            CURRENT_STATE <= STH_IDLE;
        end else begin
            case (CURRENT_STATE)
                
                STH_IDLE: begin
                    if(HSEL && HREADY) begin
                        case (HTRANSselect)

                            HTRANS_IDLE,HTRANS_BUSY: begin
                                HREADYOUT     <= '1;
                                HRESP         <= 2'b00;
                                CURRENT_STATE <= STH_IDLE;
                            end

                            HTRANS_NONSEQ,HTRANS_SEQ: begin
                                HREADYOUT <= '0;
                                HRESP     <= 2'b01;

                                if(HWRITE) begin
                                    CURRENT_STATE <= STH_WRITE;
                                end else begin
                                    CURRENT_STATE <= STH_READ0;
                                end
                            end
                        endcase
                    end else begin //if(HSEL && HREADY)
                        HREADYOUT <= 1'b1;
                        HRESP <= 2'b00;
                    end

                end

                STH_WRITE: begin
                    HREADYOUT     <= 1'b1;
                    HRESP         <= 2'b00;
                    CURRENT_STATE <= STH_IDLE;
                end

                STH_READ0: begin
                    HREADYOUT     <= 1'b1;
                    HRESP         <= 2'b00;
                    CURRENT_STATE <= STH_IDLE;
                end

                default: begin
                    CURRENT_STATE <= STH_IDLE;
                    HREADYOUT     <= 1'b1;
                    HRESP         <= 2'b00;
                end
            endcase
        end
    end
    
endmodule