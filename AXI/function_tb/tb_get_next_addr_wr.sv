`timescale 1ns/1ps

module tb_get_next_addr_wr;

    parameter ADDR_LENGTH   = 12;
    parameter AXI_WIDTH_DA  = 32;
    parameter AXI_WIDTH_DS  = AXI_WIDTH_DA/8;         // 4 byte
    parameter AXI_WIDTH_DSB = $clog2(AXI_WIDTH_DS);   // 2 bit

    logic [ADDR_LENGTH-1:0] result;


    function automatic logic [ADDR_LENGTH - 1:0] get_next_addr_wr(
        input logic [ADDR_LENGTH-1:0] addr,
        input logic [2:0]             size,
        input logic [1:0]             burst,
        input logic [3:0]             len
    );

        logic [ADDR_LENGTH - AXI_WIDTH_DSB - 1:0] naddr;
        logic [ADDR_LENGTH-1:0] mask;

        begin
            case (burst)

                // FIXED
                2'b00: begin
                    get_next_addr_wr = addr;
                end


                // INCR
                2'b01: begin

                    if ((1 << size) < AXI_WIDTH_DS) begin

                        get_next_addr_wr = addr + (1 << size);

                    end
                    else begin

                        naddr = addr[ADDR_LENGTH-1:AXI_WIDTH_DSB];

                        naddr = naddr + 1;

                        get_next_addr_wr =
                            {naddr, {AXI_WIDTH_DSB{1'b0}}};

                    end

                end


                // WRAP
                2'b10: begin

                    // chưa test wrap
                    get_next_addr_wr = addr;

                end


                // RESERVED
                2'b11: begin

                    get_next_addr_wr = addr;

                end

            endcase
        end

    endfunction


    initial begin

        $display("======================================");
        $display(" TEST FUNCTION get_next_addr_wr");
        $display("======================================");


        // =========================================
        // TEST 1: FIXED
        // =========================================

        result = get_next_addr_wr(
            12'h010,
            3'b010,
            2'b00,
            4'd0
        );

        $display(
            "FIXED : addr=0x010 size=%b burst=%b -> next=0x%h",
            3'b010,
            2'b00,
            result
        );


        // =========================================
        // TEST 2: INCR - 1 byte
        // =========================================

        result = get_next_addr_wr(
            12'h010,
            3'b000,
            2'b01,
            4'd0
        );

        $display(
            "INCR 1B: addr=0x010 size=%b burst=%b -> next=0x%h",
            3'b000,
            2'b01,
            result
        );


        // =========================================
        // TEST 3: INCR - 2 byte
        // =========================================

        result = get_next_addr_wr(
            12'h010,
            3'b001,
            2'b01,
            4'd0
        );

        $display(
            "INCR 2B: addr=0x010 size=%b burst=%b -> next=0x%h",
            3'b001,
            2'b01,
            result
        );


        // =========================================
        // TEST 4: INCR - 4 byte
        // =========================================

        result = get_next_addr_wr(
            12'h010,
            3'b010,
            2'b01,
            4'd0
        );

        $display(
            "INCR 4B: addr=0x010 size=%b burst=%b -> next=0x%h",
            3'b010,
            2'b01,
            result
        );


        // =========================================
        // TEST 5: INCR - tiếp tục từ 0x014
        // =========================================

        result = get_next_addr_wr(
            12'h014,
            3'b010,
            2'b01,
            4'd0
        );

        $display(
            "INCR 4B: addr=0x014 size=%b burst=%b -> next=0x%h",
            3'b010,
            2'b01,
            result
        );


        // =========================================
        // TEST 6: burst = 11
        // =========================================

        result = get_next_addr_wr(
            12'h020,
            3'b010,
            2'b11,
            4'd0
        );

        $display(
            "BURST11: addr=0x020 size=%b burst=%b -> next=0x%h",
            3'b010,
            2'b11,
            result
        );


        $finish;

    end

endmodule