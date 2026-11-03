`timescale 1ns/1ps

`define BURST_TYPE_WRAPP_ENABLED

module tb_get_next_addr_wr_wrap;

    parameter ADDR_LENGTH   = 12;
    parameter AXI_WIDTH_DA  = 32;
    parameter AXI_WIDTH_DS  = AXI_WIDTH_DA/8;          // 4 bytes
    parameter AXI_WIDTH_DSB = $clog2(AXI_WIDTH_DS);    // 2 bits

    logic [ADDR_LENGTH-1:0] addr;
    logic [ADDR_LENGTH-1:0] next_addr;
    logic [ADDR_LENGTH-1:0] mask;

    //========================================================
    // get_wrap_mask
    //========================================================
    function automatic logic [ADDR_LENGTH-1:0] get_wrap_mask(
        input logic [2:0] size,
        input logic [3:0] len
    );

        begin
            case (size)
                3'b000: get_wrap_mask = (1   * len) - 1;
                3'b001: get_wrap_mask = (2   * len) - 1;
                3'b010: get_wrap_mask = (4   * len) - 1;
                3'b011: get_wrap_mask = (8   * len) - 1;
                3'b100: get_wrap_mask = (16  * len) - 1;
                3'b101: get_wrap_mask = (32  * len) - 1;
                3'b110: get_wrap_mask = (64  * len) - 1;
                3'b111: get_wrap_mask = (128 * len) - 1;
            endcase
        end

    endfunction


    //========================================================
    // get_next_addr_wr
    //========================================================
    function automatic logic [ADDR_LENGTH-1:0] get_next_addr_wr(
        input logic [ADDR_LENGTH-1:0] addr,
        input logic [2:0]             size,
        input logic [1:0]             burst,
        input logic [3:0]             len
    );

        logic [ADDR_LENGTH-AXI_WIDTH_DSB-1:0] naddr;
        logic [ADDR_LENGTH-1:0] mask;

        begin
            case (burst)

                // FIXED
                2'b00:
                    get_next_addr_wr = addr;


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
                    mask = get_wrap_mask(size, len);

                    get_next_addr_wr =
                        (addr & ~mask) |
                        (((addr & mask) + (1 << size)) & mask);
                end


                // RESERVED
                2'b11:
                    get_next_addr_wr = addr;

            endcase
        end

    endfunction


    //========================================================
    // TEST
    //========================================================
    initial begin

        $display("=====================================");
        $display("       TEST WRAP BURST");
        $display("=====================================");

        // size = 010 -> 4 bytes
        // len  = 4
        // mask = 4*4 - 1 = 15 = 0x00F

        mask = get_wrap_mask(3'b010, 4'd4);

        $display("size = 010");
        $display("len  = 4");
        $display("mask = 0x%h", mask);

        // Start address
        addr = 12'h010;

        // Beat 1
        next_addr = get_next_addr_wr(
            addr,
            3'b010,
            2'b10,
            4'd4
        );

        $display("addr = 0x%h -> next = 0x%h",
                 addr, next_addr);

        addr = next_addr;


        // Beat 2
        next_addr = get_next_addr_wr(
            addr,
            3'b010,
            2'b10,
            4'd4
        );

        $display("addr = 0x%h -> next = 0x%h",
                 addr, next_addr);

        addr = next_addr;


        // Beat 3
        next_addr = get_next_addr_wr(
            addr,
            3'b010,
            2'b10,
            4'd4
        );

        $display("addr = 0x%h -> next = 0x%h",
                 addr, next_addr);

        addr = next_addr;


        // Beat 4 -> WRAP back
        next_addr = get_next_addr_wr(
            addr,
            3'b010,
            2'b10,
            4'd4
        );

        $display("addr = 0x%h -> next = 0x%h",
                 addr, next_addr);


        $finish;

    end

endmodule