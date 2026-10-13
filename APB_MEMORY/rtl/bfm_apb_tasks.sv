`ifndef BFM_APB_TASKS_V
`define BFM_APB_TASKS_V

task apb_write(
    input logic [31:0] addr,
    input logic [31:0] data,
    input logic [2:0] size
);

    @(posedge PCLK);
    PADDR   <= #1 addr;
    PWRITE  <= #1 1'b1;
    PSEL    <= #1 decoder(addr);
    PWDATA  <= #1 data;
    PSTRB   <= #1 get_pstrob(addr,size);
    @(posedge PCLK);
    PENABLE <= #1 1'b1;
    @(posedge PCLK);
    while (get_pready(addr) == 1'b0) @(posedge PCLK);
    `ifndef LOW_POWER
    PADDR   <= #1 32'h0;
    PWRITE  <= #1 1'b0;
    PWDATA  <= #1 ~32'h0;
    `endif

    PSEL    <= #1 {P_NUM{1'b0}};
    PENABLE <= #1 1'b0;
    if(get_pslverr(addr) == 1'b1) $display($time,"%m PSLVERR");

endtask

task apb_read(
    input logic [31:0] addr,
    output logic [31:0] data,
    input logic [2:0] size
);

@(posedge PCLK);
PADDR   <= #1 addr;
PWRITE  <= #1 1'b0;
PSEL    <= #1 decoder(addr);
PSTRB   <= #1 4'hF;
@(posedge PCLK);
PENABLE <= #1 1'b1;
@(posedge PCLK);
while (get_pready(addr)==1'b0) @(posedge PCLK);
`ifndef LOW_POWER
PADDR   <= #1 32'h0;

`endif // LOW_POWER
PSEL    <= #1 {P_NUM{1'b0}};
PENABLE <= #1 1'b0;
if(get_pslverr(addr) == 1'b1) $display($time,"%m PSLVERR");
data    = get_prdata(addr);
    
endtask

function automatic logic [3:0] decoder(
        input logic [31:0] addr
    );

        begin
            if(P_NUM >= 1) begin
                if((addr[31:16]>=P_ADDR_START0)&&
                (addr<=P_ADDR_START0 + P_ADDR_SIZE0 - 1))
                decoder = 1<<0;
            end
            if(P_NUM >= 2) begin
                if((addr[31:16]>=P_ADDR_START1)&&
                (addr[31:16]<=P_ADDR_START1 + P_ADDR_SIZE1 - 1))
                decoder = 1<<1;
            end
            if(P_NUM >= 3) begin
                if((addr[31:16]>=P_ADDR_START2)&&
                (addr[31:16]<=P_ADDR_START2 + P_ADDR_SIZE2 - 1))
                decoder = 1<<2;
            end
            if(decoder == 0) begin
                $display ($time,"%m ERROR address range.");
            end
        end
        
    endfunction

    function automatic logic [P_STRB-1:0] get_pstrob(
        input logic [31:0] addr,
        input logic [2:0] size
    );

        begin
            case (addr[1:0])
                
                2'b00: case (size)
                    3'd1: get_pstrob = 4'b0001;
                    3'd2: get_pstrob = 4'b0011;
                    3'd4: get_pstrob = 4'b1111;
                    default: $display($time, "%m mis-aligned access");
                    
                endcase

                2'b01: case (size)
                    3'd1: get_pstrob = 4'b0010;
                    default: $display($time, "%m mis-aligned access");
                    
                endcase

                2'b10: case (size)
                    3'd1: get_pstrob = 4'b0100;
                    3'd2: get_pstrob = 4'b1100;
                    default: $display($time, "%m mis-aligned access");
                    
                endcase

                2'b11: case (size)
                    3'd1: get_pstrob = 4'b1000;
                    default: $display($time, "%m mis-aligned access");
                    
                endcase

            endcase
        end
        
    endfunction

    function automatic logic get_pslverr(
        input logic [31:0] addr
    );
        begin
            if(P_NUM >= 1) begin
                if( (addr[31:16] >= P_ADDR_START0) &&
                    (addr[31:16] <= P_ADDR_START0 + P_ADDR_SIZE0 - 1))
                    get_pslverr = PSLVERR[0];
            end
            if(P_NUM >= 2) begin
                if( (addr[31:16] >= P_ADDR_START1) &&
                    (addr[31:16] <= P_ADDR_START1 + P_ADDR_SIZE1 - 1))
                    get_pslverr = PSLVERR[1];
            end
            if(P_NUM >= 3) begin
                if( (addr[31:16] >= P_ADDR_START2) &&
                    (addr[31:16] <= P_ADDR_START2 + P_ADDR_SIZE2 - 1))
                    get_pslverr = PSLVERR[2];
            end
        end
        
    endfunction

    function automatic logic [31:0] get_prdata(
        input logic [31:0] addr
    );
        if(P_NUM >= 1) begin
                if( (addr[31:16] >= P_ADDR_START0) &&
                    (addr[31:16] <= P_ADDR_START0 + P_ADDR_SIZE0 - 1))
                    get_prdata = PRDATA0;
            end
            if(P_NUM >= 2) begin
                if( (addr[31:16] >= P_ADDR_START1) &&
                    (addr[31:16] <= P_ADDR_START1 + P_ADDR_SIZE1 - 1))
                    get_prdata = PRDATA1;
            end
            if(P_NUM >= 3) begin
                if( (addr[31:16] >= P_ADDR_START2) &&
                    (addr[31:16] <= P_ADDR_START2 + P_ADDR_SIZE2 - 1))
                    get_prdata = PRDATA2;
            end
        
    endfunction

    `endif