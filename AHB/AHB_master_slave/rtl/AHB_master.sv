module AHB_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter master_MEMORY_DEPTH = 32
)(
    //--------------------------------------------------------//
    //Global signals
    input logic HRESETn,
    input logic HCLK,

    //--------------------------------------------------------//
    //Transfer response
    input logic HREADY, //Is the current transfer finished?
    input logic HRESP,  //Did the transfer succeed or fail?
    
    //--------------------------------------------------------//
    // Read Data
    input logic [DATA_WIDTH - 1:0] HRDATA, //Read data returned by the Slave

    //--------------------------------------------------------//
    // Address control
    output logic [ADDR_WIDTH - 1:0] HADDR, //Address the Master wants to access
    output logic HWRITE, //1 = write, 0 = read


    //--------------------------------------------------------//
    // Write Data
    output logic [DATA_WIDTH - 1:0] HWDATA, //Data the Master wants to write
 
    //--------------------------------------------------------//
    //Not using
    // 
    // output logic [2:0] HSIZE,
    // output logic [2:0] HBURST,
    // output logic [3:0] HPROT,
    // output logic [1:0] HTRANS,
    // output logic HMASTLOCK


    //--------------------------------------------------------//
    //User defined signal
    input logic [DATA_WIDTH-1:0] data_top,
    input logic write_top,
    input logic enable,
    input logic [ADDR_WIDTH-1:0] addr_top 
    
);

    localparam MEM_ADDR_WIDTH = $clog2(master_MEMORY_DEPTH);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        ADDR_PHASE = 2'b01,
        DATA_PHASE = 2'b10
    } state_t;

    state_t current_state,next_state;

    logic [DATA_WIDTH-1:0] master_memory [0:master_MEMORY_DEPTH-1];

    //========================================================
    // State register
    //========================================================
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    //========================================================
    // Output logic
    //========================================================
    always_comb begin
        next_state = current_state;
        // Default values
        HADDR  = '0;
        HWRITE = 1'b0;
        HWDATA = '0;

        case (current_state)

            IDLE: begin
                if (enable)
                next_state = ADDR_PHASE;
            end

            ADDR_PHASE: begin
                HADDR  = addr_top;
                HWRITE = write_top;
                if (HREADY) next_state = DATA_PHASE;
            end

            DATA_PHASE: begin
                HADDR  = addr_top;
                HWRITE = write_top;

                if (write_top) HWDATA = data_top;
                if (HREADY) next_state = IDLE;
                
            end

            default: begin
                HADDR  = '0;
                HWRITE = 1'b0;
                HWDATA = '0;
            end

        endcase
        
    end

    integer i;
    always_ff @(posedge HCLK or negedge HRESETn) begin
            if(!HRESETn) begin
                for (i = 0; i < master_MEMORY_DEPTH; i = i+ 1)
                master_memory[i] <= '0;
            end else if (current_state == DATA_PHASE && !write_top && HREADY) begin
                master_memory[HADDR[MEM_ADDR_WIDTH+1:2]] <= HRDATA;
            end
        end



endmodule