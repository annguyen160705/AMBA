`timescale 1ns/1ps

module tb_get_wrap_mask;

    parameter ADDR_LENGTH = 12;

    logic [ADDR_LENGTH-1:0] result;


    function automatic logic [ADDR_LENGTH-1:0] get_wrap_mask(
        input logic [2:0] size,
        input logic [3:0] len
    );

        begin
            case (size)
                3'b000: get_wrap_mask = (1   * len) - 1;   // 1 byte
                3'b001: get_wrap_mask = (2   * len) - 1;   // 2 bytes
                3'b010: get_wrap_mask = (4   * len) - 1;   // 4 bytes
                3'b011: get_wrap_mask = (8   * len) - 1;   // 8 bytes
                3'b100: get_wrap_mask = (16  * len) - 1;   // 16 bytes
                3'b101: get_wrap_mask = (32  * len) - 1;   // 32 bytes
                3'b110: get_wrap_mask = (64  * len) - 1;   // 64 bytes
                3'b111: get_wrap_mask = (128 * len) - 1;   // 128 bytes
            endcase
        end

    endfunction


    initial begin

        $display("========================================");
        $display("       TEST get_wrap_mask");
        $display("========================================");

        // size = 1 byte, len = 4
        result = get_wrap_mask(3'b000, 4'd4);
        $display("size=000 len=4 -> mask=%h (%d)", result, result);

        // size = 2 bytes, len = 4
        result = get_wrap_mask(3'b001, 4'd4);
        $display("size=001 len=4 -> mask=%h (%d)", result, result);

        // size = 4 bytes, len = 4
        result = get_wrap_mask(3'b010, 4'd4);
        $display("size=010 len=4 -> mask=%h (%d)", result, result);

        // size = 4 bytes, len = 8
        result = get_wrap_mask(3'b010, 4'd8);
        $display("size=010 len=8 -> mask=%h (%d)", result, result);

        // size = 8 bytes, len = 4
        result = get_wrap_mask(3'b011, 4'd4);
        $display("size=011 len=4 -> mask=%h (%d)", result, result);

        $finish;

    end

endmodule