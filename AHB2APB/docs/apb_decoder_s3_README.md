
Scenario: The APB Master targets Slave 1.

PADDR = 32'hC000_1234

PSELin = 1'b1

```systemverilog
assign tpaddr = PADDR[31:16]; // tpaddr extracts the top 16 bits: 16'hC000

    always_comb begin
        // Output defaults are temporarily 0
        PSELout1 = 1'b0; 
        
        // P_NUM = 3 (3 > 0 is True)
        // tpaddr = 16'hC000 (16'hC000 >= 16'hC000 is True)
        // tpaddr <= P_ADDR_END1 (16'hC000 <= 16'hC000 is True)
        if (P_NUM > 0 && tpaddr >= P_ADDR_START1 && tpaddr <= P_ADDR_END1) begin // All True!
            PSELout1 = PSELin; // PSELout1 = 1'b1 (Overrides the default 0)
        end
        
        // tpaddr = 16'hC000 (16'hC000 >= 16'hC010 is False. Skips Slave 2)
        if (P_NUM > 1 && tpaddr >= P_ADDR_START2 && tpaddr <= P_ADDR_END2) begin 
            // ... skipped ...
        end
        
        // tpaddr = 16'hC000 (16'hC000 >= 16'hC020 is False. Skips Slave 3)
        if (P_NUM > 2 && tpaddr >= P_ADDR_START3 && tpaddr <= P_ADDR_END3) begin
            // ... skipped ...
        end
    end
    // Final Result: PSELout1 = 1, PSELout2 = 0, PSELout3 = 0.
```