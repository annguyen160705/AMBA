module AHB_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter slave_MEMORY_DEPTH = 32
) (
    //--------------------------------------------------------//
    //Global signals
    input logic HRESETn,
    input logic HCLK,

    //--------------------------------------------------------//
    //Transfer response
    output logic HREADYOUT, //Slave has finished this transfer.
    output logic HRESP,     //Was the transfer successful or did an error occur?
    // HRESP = 0 → OKAY / successful
    // HRESP = 1 → ERROR
    //--------------------------------------------------------//
    // Read Data
    output logic [DATA_WIDTH - 1:0] HRDATA,
    /*the Slave can send data to an IP, but HRDATA 
    is normally reserved for sending read data back to the Master.*/
    //--------------------------------------------------------//
    // Address control
    input logic [ADDR_WIDTH - 1:0] HADDR,
    input logic HWRITE,
    //Coming from the Master.
    //--------------------------------------------------------//
    // Write Data
    input logic [DATA_WIDTH - 1:0] HWDATA
    //HWDATA is the write data sent from the AHB Master to the AHB Slave.
        //--------------------------------------------------------//
    //Not using
    // input logic HSELx;
    // 
    // input logic [2:0] HSIZE,
    // input logic [2:0] HBURST,
    // input logic [3:0] HPROT,
    // input logic [1:0] HTRANS,
    // input logic HMASTLOCK
);

    localparam MEM_ADDR_WIDTH = $clog2(slave_MEMORY_DEPTH);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        ADDR_PHASE = 2'b01,
        DATA_PHASE = 2'b10
    } state_t;

    state_t current_state;
    
    logic [DATA_WIDTH-1:0] slave_memory [0:slave_MEMORY_DEPTH-1];


    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            current_state <= IDLE;
        end else begin
            case (current_state)
            
            IDLE: 
            begin
                HREADYOUT    <= 1'b0;
                next_state <= ADDR_PHASE;
            end
            ADDR_PHASE:
            begin     
                next_state <= DATA_PHASE;
            end
            DATA_PHASE:
            begin
                if(HWRITE) begin
                    // HWRITE = 1 → WRITE → Slave stores HWDATA
                    // HWRITE = 0 → READ  → Slave returns HRDATA
                    slave_memory[HADDR[MEM_ADDR_WIDTH+1:2]] <= HWDATA;
                end else begin
                    HRDATA <= slave_memory[HADDR[MEM_ADDR_WIDTH+1:2]];
                    //HADDR = 4
                    //00000000 00000000 00000000 0[00001]00
                    //slave_memory[1] <= HWDATA;

                end
                HREADYOUT <= 1'b1;
                HRESP        <= 1'b1;
                next_state <= IDLE;
            end

            default: begin
                next_state <= IDLE;
            end
        endcase
        end
    end

    

endmodule