`timescale 1ns/1ns

// =============================================================================
// TOP
//   top_tb (AHB master stimulus)
//        |
//        v
//   AHB-to-AHB bridge (slave_core + FIFOs + master_core)
//        |
//        v
//   ahb_lite_s3
//      |   |   |
//      v   v   v
//    mem0 mem1 mem2
//
// Notes
//   * No BFM is instantiated here.
//   * HCLK/HRESETn are driven by the testbench.
//   * The testbench directly drives the upstream AHB interface.
//   * The supplied ahb2ahb.sv wrapper does not expose sHREADYout, so this
//     top instantiates the bridge cores/FIFOs directly.
// =============================================================================

module top #(
    parameter int unsigned SIZE_IN_BYTES = 1024,
    parameter int unsigned MEM_DELAY     = 0,
    parameter int unsigned FIFO_AW       = 5,

    parameter logic [15:0] HSEL0_START = 16'h0000,
    parameter logic [15:0] HSEL0_SIZE  = 16'h0100,
    parameter logic [15:0] HSEL1_START = 16'h1000,
    parameter logic [15:0] HSEL1_SIZE  = 16'h0100,
    parameter logic [15:0] HSEL2_START = 16'h2000,
    parameter logic [15:0] HSEL2_SIZE  = 16'h0100
) (
    input  logic        HCLK,
    input  logic        HRESETn,

    // -------------------------------------------------------------------------
    // Upstream AHB slave interface.
    // Driven directly by top_tb.
    // -------------------------------------------------------------------------
    input  logic        sHSEL,
    input  logic [31:0] sHADDR,
    input  logic [1:0]  sHTRANS,
    input  logic        sHWRITE,
    input  logic [2:0]  sHSIZE,
    input  logic [2:0]  sHBURST,
    input  logic [31:0] sHWDATA,

    output logic [31:0] sHRDATA,
    output logic [1:0]  sHRESP,
    output logic        sHREADYout
);

    // =========================================================================
    // Upstream HREADY feedback
    // =========================================================================
    // There is only one upstream slave in this standalone setup.  Therefore the
    // bus-ready input seen by the bridge is the same global ready returned by
    // the bridge itself.
    logic sHREADYin;
    assign sHREADYin = sHREADYout;

    // =========================================================================
    // Forward FIFO: upstream request -> downstream master core
    // =========================================================================
    logic               fwd_wr_rdy;
    logic               fwd_wr_vld;
    logic [31:0]        fwd_wr_dat;
    logic               fwd_rd_rdy;
    logic               fwd_rd_vld;
    logic [31:0]        fwd_rd_dat;
    logic               fwd_full;
    logic               fwd_empty;
    logic [FIFO_AW:0]   fwd_cnt_rd;
    logic [FIFO_AW:0]   fwd_cnt_wr;

    // =========================================================================
    // Backward FIFO: downstream read response -> upstream slave core
    // =========================================================================
    logic               bwd_rd_rdy;
    logic               bwd_rd_vld;
    logic [31:0]        bwd_rd_dat;
    logic               bwd_wr_rdy;
    logic               bwd_wr_vld;
    logic [31:0]        bwd_wr_dat;
    logic               bwd_full;
    logic               bwd_empty;
    logic [FIFO_AW:0]   bwd_cnt_rd;
    logic [FIFO_AW:0]   bwd_cnt_wr;

    // =========================================================================
    // Bridge master-side AHB signals
    // =========================================================================
    logic        mHBUSREQ;
    logic        mHGRANT;
    logic [31:0] mHADDR;
    logic [1:0]  mHTRANS;
    logic        mHWRITE;
    logic [2:0]  mHSIZE;
    logic [2:0]  mHBURST;
    logic [3:0]  mHPROT;
    logic [31:0] mHWDATA;
    logic [31:0] mHRDATA;
    logic [1:0]  mHRESP;
    logic        mHREADY;

    // One downstream master only -> no arbiter required.
    assign mHGRANT = mHBUSREQ;

    // ahb2ahb does not carry HPROT, so use a fixed legal value.
    assign mHPROT = 4'b0011;

    // =========================================================================
    // AHB-to-AHB bridge: SLAVE CORE
    // =========================================================================
    ahb2ahb_slave_core #(
        .FIFO_AW(FIFO_AW)
    ) u_ahb2ahb_slave_core (
        .HRESETn    (HRESETn),
        .HCLK       (HCLK),

        .HSEL       (sHSEL),
        .HADDR      (sHADDR),
        .HTRANS     (sHTRANS),
        .HWRITE     (sHWRITE),
        .HSIZE      (sHSIZE),
        .HBURST     (sHBURST),
        .HWDATA     (sHWDATA),
        .HRDATA     (sHRDATA),
        .HRESP      (sHRESP),
        .HREADYin   (sHREADYin),
        .HREADYout  (sHREADYout),

        .fwr_clk    (),
        .fwr_rdy    (fwd_wr_rdy),
        .fwr_vld    (fwd_wr_vld),
        .fwr_dat    (fwd_wr_dat),
        .fwr_full   (fwd_full),
        .fwr_cnt    (fwd_cnt_wr),

        .brd_clk    (),
        .brd_rdy    (bwd_rd_rdy),
        .brd_vld    (bwd_rd_vld),
        .brd_dat    (bwd_rd_dat),
        .brd_empty  (bwd_empty),
        .brd_cnt    (bwd_cnt_rd)
    );

    // =========================================================================
    // FORWARD FIFO
    // =========================================================================
    ahb2ahb_fifo #(
        .FDW (32),
        .FAW (FIFO_AW)
    ) u_fwd_fifo (
        .rst     (~HRESETn),
        .clr     (1'b0),
        .clk     (HCLK),

        .wr_rdy  (fwd_wr_rdy),
        .wr_vld  (fwd_wr_vld),
        .wr_din  (fwd_wr_dat),

        .rd_rdy  (fwd_rd_rdy),
        .rd_vld  (fwd_rd_vld),
        .rd_dout (fwd_rd_dat),

        .full    (fwd_full),
        .empty   (fwd_empty),
        .fullN   (),
        .emptyN  (),
        .rd_cnt  (fwd_cnt_rd),
        .wr_cnt  (fwd_cnt_wr)
    );

    // =========================================================================
    // AHB-to-AHB bridge: MASTER CORE
    // =========================================================================
    ahb2ahb_master_core #(
        .FIFO_AW(FIFO_AW)
    ) u_ahb2ahb_master_core (
        .HRESETn   (HRESETn),
        .HCLK      (HCLK),

        .HGRANT    (mHGRANT),
        .HRDATA    (mHRDATA),
        .HRESP     (mHRESP),
        .HREADY    (mHREADY),

        .HBUSREQ   (mHBUSREQ),
        .HADDR     (mHADDR),
        .HTRANS    (mHTRANS),
        .HWRITE    (mHWRITE),
        .HSIZE     (mHSIZE),
        .HBURST    (mHBURST),
        .HWDATA    (mHWDATA),

        .frd_clk   (),
        .frd_rdy   (fwd_rd_rdy),
        .frd_vld   (fwd_rd_vld),
        .frd_dat   (fwd_rd_dat),
        .frd_empty (fwd_empty),
        .frd_cnt   (fwd_cnt_rd),

        .bwr_clk   (),
        .bwr_rdy   (bwd_wr_rdy),
        .bwr_vld   (bwd_wr_vld),
        .bwr_dat   (bwd_wr_dat),
        .bwr_full  (bwd_full),
        .bwr_cnt   (bwd_cnt_wr)
    );

    // =========================================================================
    // BACKWARD FIFO
    // =========================================================================
    ahb2ahb_fifo #(
        .FDW (32),
        .FAW (FIFO_AW)
    ) u_bwd_fifo (
        .rst     (~HRESETn),
        .clr     (1'b0),
        .clk     (HCLK),

        .wr_rdy  (bwd_wr_rdy),
        .wr_vld  (bwd_wr_vld),
        .wr_din  (bwd_wr_dat),

        .rd_rdy  (bwd_rd_rdy),
        .rd_vld  (bwd_rd_vld),
        .rd_dout (bwd_rd_dat),

        .full    (bwd_full),
        .empty   (bwd_empty),
        .fullN   (),
        .emptyN  (),
        .rd_cnt  (bwd_cnt_rd),
        .wr_cnt  (bwd_cnt_wr)
    );

    // =========================================================================
    // AHB-Lite 1-master / 3-slave interconnect
    // =========================================================================
    logic [31:0] S_HADDR;
    logic [3:0]  S_HPROT;
    logic [1:0]  S_HTRANS;
    logic        S_HWRITE;
    logic [2:0]  S_HSIZE;
    logic [2:0]  S_HBURST;
    logic [31:0] S_HWDATA;
    logic        S_HREADY;

    logic        S_HSEL      [0:2];
    logic [31:0] S_HRDATA    [0:2];
    logic [1:0]  S_HRESP     [0:2];
    logic        S_HREADYout [0:2];

    ahb_lite_s3 #(
        .P_HSEL0_START (HSEL0_START),
        .P_HSEL0_SIZE  (HSEL0_SIZE),
        .P_HSEL1_START (HSEL1_START),
        .P_HSEL1_SIZE  (HSEL1_SIZE),
        .P_HSEL2_START (HSEL2_START),
        .P_HSEL2_SIZE  (HSEL2_SIZE)
    ) u_ahb_lite_s3 (
        .HRESETn (HRESETn),
        .HCLK    (HCLK),

        .M_HADDR  (mHADDR),
        .M_HTRANS (mHTRANS),
        .M_HWRITE (mHWRITE),
        .M_HSIZE  (mHSIZE),
        .M_HBURST (mHBURST),
        .M_HPROT  (mHPROT),
        .M_HWDATA (mHWDATA),
        .M_HRDATA (mHRDATA),
        .M_HRESP  (mHRESP),
        .M_HREADY (mHREADY),

        .HWRITE  (S_HWRITE),
        .HADDR   (S_HADDR),
        .HTRANS  (S_HTRANS),
        .HSIZE   (S_HSIZE),
        .HBURST  (S_HBURST),
        .HPROT   (S_HPROT),
        .HWDATA  (S_HWDATA),
        .HREADY  (S_HREADY),

        .HSEL0   (S_HSEL[0]),
        .HRESP0  (S_HRESP[0]),
        .HRDATA0 (S_HRDATA[0]),
        .HREADY0 (S_HREADYout[0]),

        .HSEL1   (S_HSEL[1]),
        .HRESP1  (S_HRESP[1]),
        .HRDATA1 (S_HRDATA[1]),
        .HREADY1 (S_HREADYout[1]),

        .HSEL2   (S_HSEL[2]),
        .HRESP2  (S_HRESP[2]),
        .HRDATA2 (S_HRDATA[2]),
        .HREADY2 (S_HREADYout[2]),

        .REMAP   (1'b0)
    );

    // =========================================================================
    // Three AHB memory slaves
    // =========================================================================
    genvar GM;
    generate
        for (GM = 0; GM < 3; GM = GM + 1) begin : MEM_BLK
            mem_ahb #(
                .SIZE_IN_BYTES (SIZE_IN_BYTES),
                .DELAY         (MEM_DELAY)
            ) u_mem_ahb (
                .HRESETn    (HRESETn),
                .HCLK       (HCLK),
                .HSEL       (S_HSEL[GM]),
                .HADDR      (S_HADDR),
                .HTRANS     (S_HTRANS),
                .HWRITE     (S_HWRITE),
                .HSIZE      (S_HSIZE),
                .HBURST     (S_HBURST),
                .HWDATA     (S_HWDATA),
                .HRDATA     (S_HRDATA[GM]),
                .HRESP      (S_HRESP[GM]),
                .HREADYin   (S_HREADY),
                .HREADYout  (S_HREADYout[GM])
            );
        end
    endgenerate

endmodule
