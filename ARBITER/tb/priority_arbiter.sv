`timescale 1ns/1ps

module priority_arbiter_tb;

    parameter DATA_WIDTH = 4;

    logic clk;
    logic arstn;
    logic [DATA_WIDTH-1:0] REQ;
    logic [DATA_WIDTH-1:0] GNT;

    // DUT
    priority_arbiter #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk  (clk),
        .arstn(arstn),
        .REQ  (REQ),
        .GNT  (GNT)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    initial begin

        // Initial values
        clk  = 1'b0;
        arstn = 1'b0;
        REQ  = '0;

        // Reset
        #10;
        arstn = 1'b1;

        // Test 1: No request
        REQ = 4'b0000;
        #10;

        // Test 2: Request 0
        REQ = 4'b0001;
        #10;

        // Test 3: Request 1
        REQ = 4'b0010;
        #10;

        // Test 4: Multiple requests
        // REQ[3] has highest priority
        REQ = 4'b0111;
        #10;

        // Test 5: Multiple requests
        REQ = 4'b1011;
        #10;

        // Test 6: All requests
        REQ = 4'b1111;
        #10;

        // Test 7: Only highest priority
        REQ = 4'b1000;
        #10;

        // Finish
        $finish;
    end

    // Monitor
    initial begin
        $monitor(
            "TIME=%0t | arstn=%b | REQ=%b | GNT=%b",
            $time, arstn, REQ, GNT
        );
    end

endmodule