`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2024 11:04:29 PM
// Design Name: 
// Module Name: Decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Decoder(
input [1:0] sel,
output reg Hsel_1,Hsel_2,Hsel_3,Hsel_4

);
   always@(*)
       begin
            case(sel)
                2'b00: begin
                    Hsel_1 = 1'b1;
                    Hsel_2 = 1'b0;
                    Hsel_3 = 1'b0;
                    Hsel_4 = 1'b0;
                       end
                       
                 2'b01: begin
                     Hsel_1 = 1'b0;
                     Hsel_2 = 1'b1;
                     Hsel_3 = 1'b0;
                     Hsel_4 = 1'b0;
                        end
                        
                  2'b10: begin
                      Hsel_1 = 1'b0;
                      Hsel_2 = 1'b0;
                      Hsel_3 = 1'b1;
                      Hsel_4 = 1'b0;     
                         end
                   
                   2'b11: begin
                       Hsel_1 = 1'b0;
                       Hsel_2 = 1'b0;
                       Hsel_3 = 1'b0;
                       Hsel_4 = 1'b1;
                          end
                    //nothing happens in default case
                    default: begin
                         Hsel_1 = 1'b0;
                         Hsel_2 = 1'b0;
                         Hsel_3 = 1'b0;
                         Hsel_4 = 1'b0;
                              end
                   endcase
                end    
endmodule