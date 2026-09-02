module fixed_priority_arbiter_tb;

    logic       clk;
    logic       rst_n;
    logic [3:0] REQ;
    logic [3:0] GNT;

    // DUT
    fixed_priority_arbiter dut (
        .clk   (clk),
        .rst_n (rst_n),
        .REQ   (REQ),
        .GNT   (GNT)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    initial begin
        // Initial values
        clk   = 1'b0;
        rst_n = 1'b0;
        REQ   = 4'b0000;

        // Apply reset
        #12;
        rst_n = 1'b1;

        // Test 1: No request
        #10;
        REQ = 4'b0000;

        // Test 2: REQ[0]
        #10;
        REQ = 4'b0001;

        // Test 3: REQ[1]
        #10;
        REQ = 4'b0010;

        // Test 4: REQ[2]
        #10;
        REQ = 4'b0100;

        // Test 5: REQ[3]
        #10;
        REQ = 4'b1000;

        // Test 6: Multiple requests
        #10;
        REQ = 4'b0011;

        // Test 7: Multiple requests
        #10;
        REQ = 4'b1100;

        // Test 8: All requests
        #10;
        REQ = 4'b1111;

        #10;
        $finish;
    end

    // Display results
    initial begin
        $monitor(
            "TIME=%0t | rst_n=%b | REQ=%b | GNT=%b",
            $time, rst_n, REQ, GNT
        );
    end

endmodule