`timescale 1ns/1ns

`ifndef HCLK_FREQ
`define HCLK_FREQ   50_000_000
`endif

`ifndef PCLK_FREQ
`define PCLK_FREQ   50_000_000
`endif // PCLK_FREQ

`ifndef MEM_DELAY
`define MEM_DELAY 0
`endif // MEM_DELAY

`ifndef SIZE_IN_BYTES
`define SIZE_IN_BYTES 1024
`endif // SIZE_IN_BYTES


module top;
    localparam SIZE_IN_BYTES = `SIZE_IN_BYTES;
    localparam DELAY = `MEM_DELAY;
    

    //--------------------------------------------------------//
    // Control signals
    logic HRESETn   = 1'b0;
    logic HCLK      = 1'b0;
    logic HBUSREQ;
    logic HGRANT;
    assign HGRANT = HBUSREQ; // no arbiter
    logic [31:0]    HADDR;
    logic [3:0]     HPROT;
    logic           HLOCK;
    logic [1:0]     HTRANS;
    logic           HWRITE;
    logic [2:0]     HSIZE;
    logic [2:0]     HBURST;
    logic [31:0]    HWDATA;
    logic [31:0]    HRDATA;
    logic [1:0]     HRESP;
    logic           HREADY;
    logic           HSEL;
    assign HSEL = HTRANS[1];

    //--------------------------------------------------------//
    // Slave signals
    localparam      P_NUM    = 3;
    logic           PCLK    = 1'b0;
    logic           PRESETn;
    assign          PRESETn = HRESETn;
    logic           PENABLE;
    logic [31:0]    PADDR;
    logic           PWRITE;
    logic [31:0]    PWDATA;
    logic [31:0]    PRDATA0;
    logic [31:0]    PRDATA1;
    logic [31:0]    PRDATA2;
    logic [P_NUM-1:0] PSEL;
    `ifdef AMBA_APB3
    logic [P_NUM-1:0] PREADY;
    logic [P_NUM-1:0] PSLVERR;
    `endif

    `ifdef AMBA_APB4
    logic [2:0] PPROT;
    logic [3:0] PSTRB;
    `endif // AMBA_APB4
    

    logic [32*P_NUM-1:0] PRDATA;
    assign  PRDATA0 = PRDATA[31:0];
    assign  PRDATA1 = PRDATA[63:32];
    assign  PRDATA2 = PRDATA[95:64];

    //--------------------------------------------------------//
    ahb_to_apb_s3 #(.P_PSEL0_START(16'h0000),.P_PSEL0_SIZE(16'h0010),
                    .P_PSEL1_START(16'h1000),.P_PSEL1_SIZE(16'h0010),
                    .P_PSEL2_START(16'h2000),.P_PSEL2_SIZE(16'h0010))
    u_ahb_to_apb   (
         .HRESETn        (HRESETn  )
       , .HCLK           (HCLK     )

       , .PRESETn        (PRESETn  )
       , .PCLK           (PCLK     )

       , .HSEL           (HSEL     )
       , .HTRANS         (HTRANS   )
       , .HPROT          (HPROT    )
       , .HWRITE         (HWRITE   )
       , .HSIZE          (HSIZE    )
       , .HBURST         (HBURST   )

       , .HADDR          (HADDR    )

       , .HWDATA         (HWDATA   )
       , .HRDATA         (HRDATA   )

       , .HREADYin       (HREADY   )
       , .HRESP          (HRESP    )
       , .HREADYout      (HREADY   )

       , .PENABLE        (PENABLE  )
       , .PWRITE         (PWRITE   )
       , .PSEL0          (PSEL[0]  )
       , .PSEL1          (PSEL[1]  )
       , .PSEL2          (PSEL[2]  )

       , .PADDR          (PADDR    )

       , .PWDATA         (PWDATA   )
       , .PRDATA0        (PRDATA0  )
       , .PRDATA1        (PRDATA1  )
       , .PRDATA2        (PRDATA2  )

       `ifdef AMBA_APB3
       , .PREADY0        (PREADY[0]     )
       , .PSLVERR0       (PSLVERR[0]    )
       `endif
       `ifdef AMBA_APB3
       , .PREADY1        (PREADY[1])
       , .PSLVERR1       (PSLVERR[1])
       `endif
       `ifdef AMBA_APB3
       , .PREADY2        (PREADY[2] )
       , .PSLVERR2       (PSLVERR[2])
       `endif
       `ifdef AMBA_APB4
       , .PPROT         (PPROT    )
       , .PSTRB         (PSTRB    )
       `endif
       , .CLOCK_RATIO   (2'b0) // 0=1:1, 3=async
    );

    generate
    genvar pn;
        for ( pn = 0; pn < P_NUM; pn = pn + 1) begin : P_BLOCK
            mem_apb #(.SIZE_IN_BYTES (1024)
                     ,.DELAY         (DELAY))
            u_mem_apb(
                    .PRESETn    (PRESETn)
                    ,.PCLK      (PCLK)
                    ,.PSEL      (PSEL[pn])
                    ,.PADDR     (PADDR)
                    ,.PENABLE   (PENABLE)
                    ,.PWRITE    (PWRITE)
                    ,.PWDATA    (PWDATA)
                    ,.PRDATA    (PRDATA[32*(pn+1)-1:32*pn])
                    `ifdef AMBA3
                    ,.PREADY    (PREADY[pn])
                    ,.PSLVERR   (PSLVERR[pn])
                    `endif // AMBA3
                    `ifdef AMBA4
                    ,.PPROT     (PPROT)
                    ,.PSTRB     (PSTRB)
                    `endif // AMBA4
            );
        end
    endgenerate

    localparam  HCLK_FREQ   =`HCLK_FREQ;
    localparam  HCLK_PERIOD_HALF    =1_000_000_000/(HCLK_FREQ*2);

    always #HCLK_PERIOD_HALF    HCLK <= ~HCLK;

    localparam  PCLK_FREQ   =`PCLK_FREQ;
    localparam  PCLK_PERIOD_HALF    =1_000_000_000/(PCLK_FREQ*2);

    always #PCLK_PERIOD_HALF    PCLK <= ~PCLK;

initial begin
        // 1. Assert Reset
        HRESETn <= 1'b0;
        
        // 2. Initialize Master control signals to safe IDLE states
        HBUSREQ <= 1'b0;
        HADDR   <= 32'h0;
        HPROT   <= 4'h0;
        HTRANS  <= 2'b00;  
        HWRITE  <= 1'b0;
        HSIZE   <= 3'b010; 
        HBURST  <= 3'b000; 
        HWDATA  <= 32'h0;

        repeat (5) @ (posedge HCLK);

        // 3. Deassert Reset
        HRESETn <= 1'b1;
        repeat (2) @ (posedge HCLK); 

        // =========================================================
        // TEST 1: AHB WRITE TO SLAVE 1
        // =========================================================
        $display("[%0t] Starting AHB Write...", $time);
        
        // Address Phase
        HBUSREQ <= 1'b1;
        HTRANS  <= 2'b10;         
        HWRITE  <= 1'b1;          
        HADDR   <= 32'h1000_0004; 
        
        @(posedge HCLK); // Move to Data Phase

        // Data Phase
        HTRANS  <= 2'b00;         // IDLE (No subsequent transfer)
        HWRITE  <= 1'b0;
        HWDATA  <= 32'hDEADBEEF;  // DRIVE DATA IMMEDIATELY
        HBUSREQ <= 1'b0;
        
        // Wait for APB bridge to accept the data and finish
        @(posedge HCLK);
        while (!HREADY) @(posedge HCLK); 
        $display("[%0t] AHB Write Complete!", $time);

        // =========================================================
        // TEST 2: AHB READ FROM SLAVE 1
        // =========================================================
        $display("[%0t] Starting AHB Read...", $time);
        
        // Address Phase
        HBUSREQ <= 1'b1;
        HTRANS  <= 2'b10;         
        HWRITE  <= 1'b0;          
        HADDR   <= 32'h1000_0004; 
        
        @(posedge HCLK); // Move to Data Phase

        // Data Phase
        HTRANS  <= 2'b00;         
        HBUSREQ <= 1'b0;
        
        // Wait for APB bridge to return data
        @(posedge HCLK);
        while (!HREADY) @(posedge HCLK); 
        
        // Evaluate Result
        $display("[%0t] AHB Read Complete! HRDATA = 0x%h", $time, HRDATA);
        if (HRDATA == 32'hDEADBEEF)
            $display("SUCCESS: Data successfully written and read back!");
        else
            $display("ERROR: Data mismatch.");

        // End simulation
        #50 $finish;
    end


endmodule