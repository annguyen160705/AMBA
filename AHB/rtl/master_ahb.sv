module master_ahb(
    input logic CLK_MASTER,
    input logic RESET_MASTER,
    input logic HREADY,
    input logic [31:0] HRDATA,

    // USER DEFINED SIGNAL
    input logic [31:0] data_top,
    input logic write_top,
    input logic [3:0] beat_length,
    input logic enb,
    input logic [31:0] addr_top,
    input logic wrap_enb,


    //AHB OUTPUT
    output logic [31:0] HADDR,
    output logic HWRITE,
    output logic [2:0] HSIZE,
    output logic [31:0] HWDATA,
    output logic [1:0] HTRANS,
    output logic [2:0] HBURST, 

    output logic fifo_empty,fifo_full
);
    
    typedef enum logic [2:0] {
        IDLE    = 3'b000,
        WRITE_STATE_ADDRESS = 3'b001,
        READ_STATE_ADDRESS = 3'b010,
        READ_STATE_DATA = 3'b011,
        WRITE_STATE_DATA = 3'b100
    } state_t;

    state_t present_state,next_state;

    logic [31:0] addr_internal = 32'h0000_0000;

    integer i = 0;
    logic [3:0] count = 4'b000;

    logic hburst_internal;

    logic [31:0] internal_data;
    logic [7:0]  wrap_base;
    logic [7:0] wrap_boundary;
    logic [31:0] prev_address;

    logic [3:0] wr_ptr,rd_ptr;
    logic [31:0] mem [0:14];

    assign fifo_empty = (wr_ptr == rd_ptr);
    assign fifo_full = (wr_ptr + 1) == rd_ptr;

    always_ff @(posedge CLK_MASTER) begin
        if (RESET_MASTER) begin
            for(i=0;i<15;i=i+1)begin
                mem[i] <= 0;
                wr_ptr <= 0;
                rd_ptr <= 0;
            end
                
        end else if (write_top) begin
            mem[wr_ptr] <= data_top;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end

    always_ff @(posedge CLK_MASTER) begin
        if(RESET_MASTER) begin
            present_state = IDLE;
        end else begin
            present_state <= next_state;
        end
        if((present_state == WRITE_STATE_DATA) && beat_length == 4 && HREADY && wrap_enb == 0) begin
            count <= count + 1'b1;
            rd_ptr <= rd_ptr + 1'b1;
            addr_internal = addr_internal + 'h4;
        end
    end

    always_comb begin
        case (present_state)
            
                IDLE: begin
                    HSIZE = 'BX;
                    HBURST = 'BX;
                    HTRANS = 2'b00;
                    HWDATA = 'bx;
                    count = 0;
                    addr_internal = addr_top;
                //LOGIC FOR WRITE OPERATION

                //single incremental burst
                    if(write_top && HREADY && beat_length == 1 && enb && wrap_enb == 0) begin
                        next_state = WRITE_STATE_ADDRESS;
                        HBURST = 3'b000;
                        HWRITE = 1;
                    end else if (write_top && HREADY && beat_length == 4 && enb && wrap_enb == 0) begin //LOGIC FOR INCR4 BURST
                        next_state = WRITE_STATE_ADDRESS;
                        HBURST = 3'b011;
                        HWRITE = 1;
                    end

                

                end

                
                WRITE_STATE_ADDRESS: begin
                    HSIZE = 3'b010; // 4byte
                    HWRITE = 1'b1;

                    if(HBURST == 3'b000) begin
                        HTRANS = 2'b10; // Non sequential tranfer
                        next_state = WRITE_STATE_DATA;
                    end else if (HBURST == 3'b011) begin
                        HTRANS = 2'b10; // Non sequential tranfer
                        next_state = WRITE_STATE_DATA;
                    end
                end

                WRITE_STATE_DATA: begin
                    if(HBURST == 3'b000) begin
                        if(HREADY) begin
                            next_state = IDLE;
                            HWDATA = data_top;
                        end
                    end else if (HBURST == 3'b011) begin
                        HWDATA = mem[rd_ptr];
                        HTRANS = 2'b11; // sequential tranfer
                    end
                    if(count == 3) next_state = IDLE;
                    else begin
                        next_state = WRITE_STATE_DATA;
                    end
                end


            default: begin
                next_state = IDLE;
            end
        endcase
    end

    assign HADDR = addr_internal;
endmodule