`timescale 1ns/1ps

module axi_arbiter_stom_s2
   // lint translate_off
   `protect
   // lint translate_on
     #(parameter NUM = 2)
(
       input  logic           ARESETn
     , input  logic           ACLK
     //-----------------------------------------------------------
     , input  logic  [NUM:0]  BSELECT  // selected by comparing trans_id
     , input  logic  [NUM:0]  BVALID
     , input  logic  [NUM:0]  BREADY
     , output logic  [NUM:0]  BGRANT
     //-----------------------------------------------------------
     , input  logic  [NUM:0]  RSELECT  // selected by comparing trans_id
     , input  logic  [NUM:0]  RVALID
     , input  logic  [NUM:0]  RREADY
     , input  logic  [NUM:0]  RLAST
     , output logic  [NUM:0]  RGRANT
);
     //-----------------------------------------------------------
     // read-data arbiter
     //-----------------------------------------------------------
     logic [NUM:0] rgrant_reg;
     //-----------------------------------------------------------
    typedef enum logic {
        STR_RUN = 1'b0,
        STR_WAIT = 1'b1
    } R_state_t;

    R_state_t stateR;

     always_ff @ (posedge ACLK or negedge ARESETn) begin
           if (ARESETn==1'b0) begin
               rgrant_reg  <= 'h0;
               stateR      <= STR_RUN;
           end else begin
               case (stateR)
               STR_RUN: begin
                    if (|RGRANT) begin
                       if (~|(RGRANT&RREADY&RLAST)) begin
                           rgrant_reg <= RGRANT;
                           stateR     <= STR_WAIT;
                       end
                    end
                    end // STR_RUN
               STR_WAIT: begin
                    if (|(RGRANT&RVALID&RREADY&RLAST)) begin
                        rgrant_reg <= 'h0;
                        stateR     <= STR_RUN;
                    end
                    end // STR_WAIT
               endcase
           end
     end
     //-----------------------------------------------------------
     assign RGRANT = (stateR==STR_RUN) ? priority_sel(RSELECT&RVALID)
                                       : rgrant_reg;
     //-----------------------------------------------------------
     // write-response arbiter
     //-----------------------------------------------------------
     logic [NUM:0] bgrant_reg;
     
     typedef enum logic {
        STB_RUN = 1'b0,
        STB_WAIT = 1'b1
     } B_state_t;

    B_state_t stateB;

     always_ff @ (posedge ACLK or negedge ARESETn) begin
           if (ARESETn==1'b0) begin
               bgrant_reg  <= 'h0;
               stateB      <= STB_RUN;
           end else begin
               case (stateB)
               STB_RUN: begin
                    if (|BGRANT) begin
                       if (~|(BGRANT&BREADY)) begin
                           bgrant_reg <= BGRANT;
                           stateB     <= STB_WAIT;
                       end
                    end
                    end // STB_RUN
               STB_WAIT: begin
                    if (|(BGRANT&BVALID&BREADY)) begin
                        bgrant_reg <= 'h0;
                        stateB     <= STB_RUN;
                    end
                    end // STB_WAIT
               endcase
           end
     end
     //-----------------------------------------------------------
     assign BGRANT = (stateB==STB_RUN) ? priority_sel(BSELECT&BVALID)
                                       : bgrant_reg;
     
     function automatic logic [1:0] priority_sel(
        input [NUM:0] request
     );
        casex (request)
          3'b000: priority_sel = 3'b000;
          3'bxx1: priority_sel = 3'b001;
          3'bx10: priority_sel = 3'b010;
          3'b100: priority_sel = 3'b100;
        endcase
     endfunction//-----------------------------------------------------------
     
     //-----------------------------------------------------------
   // lint translate_off
   `endprotect
   // lint translate_on
endmodule