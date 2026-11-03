`timescale 1ns/1ps

module tb_get_strb;

    parameter AXI_WIDTH_DA  = 32;
    parameter AXI_WIDTH_DS  = AXI_WIDTH_DA/8;   // 4
    parameter AXI_WIDTH_DSB = $clog2(AXI_WIDTH_DS); // 2
    parameter ADDR_LENGTH   = 12;

    logic [AXI_WIDTH_DS-1:0] result;


    function automatic logic [AXI_WIDTH_DS-1:0] get_strb(
        input logic [ADDR_LENGTH-1:0] addr,
        input logic [2:0] size
    );

        logic [AXI_WIDTH_DS-1:0] offset;

        begin
            offset = addr[AXI_WIDTH_DSB-1:0];

            case (size)
                3'b000: get_strb = {1{1'b1}}   << offset;
                3'b001: get_strb = {2{1'b1}}   << offset;
                3'b010: get_strb = {4{1'b1}}   << offset;
                3'b011: get_strb = {8{1'b1}}   << offset;
                3'b100: get_strb = {16{1'b1}}  << offset;
                3'b101: get_strb = {32{1'b1}}  << offset;
                3'b110: get_strb = {64{1'b1}}  << offset;
                3'b111: get_strb = {128{1'b1}} << offset;
            endcase
        end

    endfunction


    initial begin

        // 1 byte, offset 0
        result = get_strb(12'h010, 3'b000);
        $display("size=000 addr=010 strb=%b", result);

        // 1 byte, offset 1
        result = get_strb(12'h011, 3'b000);
        $display("size=000 addr=011 strb=%b", result);

        // 2 byte, offset 0
        result = get_strb(12'h010, 3'b001);
        $display("size=001 addr=010 strb=%b", result);

        // 2 byte, offset 2
        result = get_strb(12'h012, 3'b001);
        $display("size=001 addr=012 strb=%b", result);

        // 4 byte
        result = get_strb(12'h010, 3'b010);
        $display("size=010 addr=010 strb=%b", result);

        $finish;
    end

endmodule