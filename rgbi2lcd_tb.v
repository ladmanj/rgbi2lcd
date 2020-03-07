/* ****************************************************************************
-- (C) Copyright 2020 Jakub Ladman - All rights reserved.
-- Source file: rgbi2lcd_tb.v                
-- Date:        March 2020
-- Author:      ladmanj
-- Description: 50Hz RGBI to VGA LCD convertor - test bench
-- Language:    Verilog-2001 and VHDL-1993
-- Simulation:  Icarus Verilog 
-- Synthesis:   Icestorm 
-- License:     This project is licensed with the CERN Open Hardware Licence
--              v1.2.  You may redistribute and modify this project under the
--              terms of the CERN OHL v.1.2. (http://ohwr.org/cernohl).
--              This project is distributed WITHOUT ANY EXPRESS OR IMPLIED
--              WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
--              AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN OHL
--              v.1.2 for applicable Conditions.
--
-- ***************************************************************************/
`timescale 1ns / 100fs
`define I_CLK_P 28.19363387747047
`define O_CLK_P 39.80257920713262

module tb();

parameter DATALEN = 17732336;

    reg [4:0] test_memory [0:DATALEN];
    reg clk_35;
    reg clk_25;
//    reg [15:0]
    integer adr;
    reg R,G,B,I,S;
    reg [2:0] in_clk_div;
    
    reg [4095:0] dumpfile;

initial begin
        $display("Loading RGBIS data");
        $readmemh("RGBIS.hexval", test_memory);
	if ($value$plusargs("df=%s", dumpfile)) begin
		$dumpfile(dumpfile);
		$dumpvars(0, dut);
	end
        clk_35 = 0;
        clk_25 = 0;
        adr = 0;
        in_clk_div = 0;
        R = 0;
        G = 0;
        B = 0;
        I = 0;
        S = 0;
//        #100000000 $finish;
end    

always #(`I_CLK_P/2) begin
    clk_35 = !clk_35;
end
    
always #(`O_CLK_P/2)
    clk_25 = !clk_25;

always @(negedge clk_35) begin
//    in_clk_div <= in_clk_div + 1;
//    if(in_clk_div == 3'd4) begin
//    in_clk_div <= 3'd0;
    adr = adr + 2;
    {S,I,B,G,R} = test_memory[adr];
    if (adr > DATALEN/4) $finish;
//    end
end

top dut
(
.vga_ck(clk_25),
.BTN_N(1'b1), // user button aka reset
.P1B1(1'b0), 
.P1B2(1'b0), 
.P1B3(S), 
.P1B4(clk_35), 
.P1B7(R), 
.P1B8(G), 
.P1B9(B), 
.P1B10(I)

//  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
//  input  P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10
);

endmodule
/*
module SB_SPRAM256KA
  (
    input   [13:0]  ADDRESS,
    input   [15:0]  DATAIN,
    input   [3:0]   MASKWREN,
    input           WREN,
    input           CHIPSELECT,
    input           CLOCK,
    input           STANDBY,
    input           SLEEP,
    input           POWEROFF,
    output reg  [15:0]  DATAOUT
  );

    reg   [15:0]  memory [0:(2^14-1)];
    
   always @(posedge CLOCK) begin
   if (CHIPSELECT) begin
    if(WREN) begin
        memory[ADRESS] = DATAIN;
    end
    DATAOUT = memory[ADDRESS];
   end
 end

endmodule
*/

