/* ****************************************************************************
-- (C) Copyright 2020 Jakub Ladman - All rights reserved.
-- Source file: rgbi2lcd.v                
-- Date:        March 2020
-- Author:      ladmanj
-- Description: 50Hz RGBI to VGA LCD convertor
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
`default_nettype none // Strictly enforce all nets to be declared
  
  `define R 3
  `define G 2
  `define B 1
  `define I 0

module top
(
  `ifdef sim
  input vga_ck,
  `endif
  
//  output LEDR_N, // on board red
//  output LEDG_N, // on board green
  input BTN_N, // user button aka reset

  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  input  P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10
  

);// module top

  wire          CLK35;
  wire          reset;
  
  `ifndef sim
  wire          vga_ck;
  `endif
  
  wire          vga_de;
  wire          vga_ck;
  wire          vga_hs;
  wire          vga_vs;
    
  wire          si;
  wire  [`R:`I] rgbi_in;
  wire  [`R:`I] rgbi_out;
  
  reg   [4:0]   in_clk_div;

  wire  [15:0]  ramadr;
  
  wire  [15:0]  ramdat_out_0;
  wire  [15:0]  ramdat_out_1;
  wire  [15:0]  ramdat_out_2;
  wire  [15:0]  ramdat_out_3;
  
  reg   [1:0]   in_cnt_h_px;
  reg   [6:0]   in_cnt_h_4px;

  reg   [8:0]   in_cnt_v;
  
  reg   [11:0]  in_3_px;
  reg   [15:0]  in_4_px;

  reg           in_sync;
  reg           in_page;
  
  reg           wr_req_1;
  reg   [1:0]   wr_req_2;
  reg           wr_req_3;
  reg           wr_req_4;
  wire          wr_en;
  
  reg           out_page;
  reg   [15:0]  out_4_px;
  reg           out_div;

  reg   [1:0]   out_cnt_h_px;
  reg   [7:0]   out_cnt_h_4px;
  reg           out_cnt_h_aux;

  reg   [8:0]   out_cnt_v;

  wire  [15:0]  outadr;
  reg   [15:0]  inadr;

  wire          u0_vid_new_frame;
  wire          u0_vid_new_line;
  wire          u0_vid_active;
  wire          u0_vga_hsync;
  wire          u0_vga_vsync;
  
  wire          border;
  
  wire  [3:0]   ram_cs;


  assign reset  = ~BTN_N;
  assign {rgbi_in,si,CLK35} = {P1B7,P1B8,P1B9,P1B10,P1B3,P1B4};

 `ifndef sim

//-----------------------------------------------------------------------------
// PLL.
//-----------------------------------------------------------------------------
SB_PLL40_CORE #(

.DIVR(4'b0010),
.DIVF(7'b1000011),
.DIVQ(3'b101),
.FILTER_RANGE(3'b001),


  .FEEDBACK_PATH("SIMPLE"),
  .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
  .FDA_FEEDBACK(4'b0000),
  .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
  .FDA_RELATIVE(4'b0000),
  .SHIFTREG_DIV_MODE(2'b00),
  .PLLOUT_SELECT("GENCLK"),
  .ENABLE_ICEGATE(1'b0)
) usb_pll_inst (
  .REFERENCECLK(CLK35),
  .PLLOUTGLOBAL(vga_ck),
  .EXTFEEDBACK(),
  .RESETB(1'b1),
  .BYPASS(1'b0),
  .LATCHINPUTVALUE(),
);
  `endif
  
// input part zx 128k +2a
  always@(posedge CLK35)
  begin
      in_sync <= si;
      if(in_clk_div == 3'd4 || ((in_sync == 1'b1) && (si == 1'b0)))   // falling edge
	in_clk_div <=0;
      else
	in_clk_div <= in_clk_div + 1;
  end


  always@(posedge CLK35)
  begin
//    in_clk_div <= in_clk_div + 1;
    if(in_clk_div == 3'd4)
    begin
//      in_clk_div <= 3'd0;
//      in_sync <= si;
      wr_req_1 <= 1'b0;
      in_cnt_h_px <= in_cnt_h_px + 1;     // pixel counter
      if(({in_cnt_h_4px,in_cnt_h_px} == 8'd254) && (in_sync == 1'b0))
      begin
        in_cnt_v <= 9'b111011101;             // init vert counter
      end
      if((in_sync == 1'b1) && (si == 1'b0))   // falling edge
      begin
        {in_cnt_h_4px,in_cnt_h_px} <= 9'b110011100;             // init horz counter
        in_cnt_v <= in_cnt_v + 1;
        if(in_cnt_v == 9'd239)
        begin
          in_page <= !in_page;            // alternating two buffers
        end 
      end
      else if(in_cnt_h_px == 2'd0)
              in_3_px[3:0] <= rgbi_in;
      else if(in_cnt_h_px == 2'd1)
              in_3_px[7:4] <= rgbi_in;
      else if(in_cnt_h_px == 2'd2)
              in_3_px[11:8] <= rgbi_in;
      else
      begin
        in_cnt_h_4px <= in_cnt_h_4px + 1;     // quad-pixel counter
        in_4_px <= {rgbi_in,in_3_px};
        wr_req_1 <= !in_cnt_v[8];
        inadr <= {in_page,in_cnt_v[7:0],in_cnt_h_4px}; // store also the address of the delayed memory write
      end
    end
  end
  
  
// output part vga
  always@(posedge vga_ck)
  begin
    out_div <= !out_div;
  end
  
  always@(posedge vga_ck)
  begin
//    out_div <= !out_div;
    if(out_div == 1'b1)
    begin
      // memory write detection
      wr_req_2 <= {wr_req_1, wr_req_2[1]};
      wr_req_3 <= 1'b0;
      wr_req_4 <= 1'b0;                         // actual memory write signal defaults to inactive
      if((wr_req_2 == 2'b01) || (wr_req_3 == 1'b1))
      begin
        if(out_cnt_h_px < 2'd2)
          wr_req_4 <= 1'b1;                     // actual memory write activated
        else
          wr_req_3 <= 1'b1;                      // write request stored
      end

      // reading data from ram, rotate and write to output
      if(out_cnt_h_px == 2'd3)
      begin
        if(ram_cs[0])
            out_4_px <= ramdat_out_0;
        else if(ram_cs[1])
            out_4_px <= ramdat_out_1;
        else if(ram_cs[2])
            out_4_px <= ramdat_out_2;
        else if(ram_cs[3])
            out_4_px <= ramdat_out_3;
      end
      else out_4_px <= {4'b000,out_4_px[15:4]};
    end
  end 
      
  assign outadr = {out_page,out_cnt_v[8:1],(out_cnt_h_4px[6:0]+7'd2)};

  assign ramadr = (wr_req_4)? inadr : outadr;
  
  assign ram_cs = 4'b0001 << ramadr[15:14];
  
  assign border = ({out_cnt_h_4px,out_cnt_h_px,out_cnt_h_aux} <= 11'd4 ) ||
                  ({out_cnt_h_4px,out_cnt_h_px,out_cnt_h_aux} >= 11'd633 )||
                  (out_cnt_v <= 11'd4 ) || (out_cnt_v >= 11'd474 );
                  
  assign {rgbi_out[`R:`I]} = (border) ? 4'b0001 : {out_4_px[`R:`B],|out_4_px[`R:`B] & out_4_px[`I]};
  
 
// ----------------------------------------------------------------------------
// Raster Counters. Count the Pixel Location in X and Y
// ----------------------------------------------------------------------------

always @ ( posedge vga_ck) begin : proc_u0_raster_cnt
 if (u0_vga_hsync) begin
         out_page <= ~in_page;
    end
 
  if ( u0_vid_new_frame == 1 ) begin
    out_cnt_v <= 9'd0;
    
  end else if ( u0_vid_new_line == 1 ) begin
    if( out_cnt_v == 9'd480 ) begin 
        out_cnt_v <= 9'd480;// Prevent rollover
    end else begin
      out_cnt_v <= out_cnt_v + 1;
    end
  end // if ( vid_new_frame == 1 ) begin

  if ( u0_vid_new_line == 1 ) begin
    {out_cnt_h_4px,out_cnt_h_px,out_cnt_h_aux} <= 11'd0;
  end else begin
    if ( {out_cnt_h_4px,out_cnt_h_px,out_cnt_h_aux} == 10'd638 ) begin
      {out_cnt_h_4px,out_cnt_h_px,out_cnt_h_aux} <= 10'd638;// Prevent rollover
    end else /*if(out_div == 1'b1)*/ begin
      
            {out_cnt_h_4px,out_cnt_h_px,out_cnt_h_aux} <= {out_cnt_h_4px,out_cnt_h_px,out_cnt_h_aux} + 1;
    end
  end  // if ( vid_new_line  == 1 ) begin

end // proc_u0_raster_cnt


// 4b rgbi single pmod - hand wired
//  assign {P1A1,               P1A2,        P1A3,   P1A4,   P1A7,   P1A8,   P1A9,      P1A10} =
//         {rgbi_out[`G], rgbi_out[`B], rgbi_out[`I], vga_de, vga_ck, vga_hs, vga_vs, rgbi_out[`R]};

// 4b rgbi single pmod - milled pcb
  assign {P1A1,        P1A2,        P1A3,   P1A4,   P1A7,   P1A8,        P1A9,       P1A10} =
       {vga_hs, rgbi_out[`R], rgbi_out[`B], vga_de, vga_ck, vga_vs, rgbi_out[`G], rgbi_out[`I]};


// ----------------------------------------------------------------------------
// VGA Timing Generator
// ----------------------------------------------------------------------------
vga_timing u0_vga_timing
(
  .reset                           ( reset             ),
  .clk_dot                         ( vga_ck            ),
  .vid_new_frame                   ( u0_vid_new_frame  ),
  .vid_new_line                    ( u0_vid_new_line   ),
  .vid_active                      ( u0_vid_active     ),
  .vga_hsync                       ( u0_vga_hsync      ),
  .vga_vsync                       ( u0_vga_vsync      )
);

assign {vga_de, vga_hs, vga_vs} = {u0_vid_active, ~u0_vga_hsync, ~u0_vga_vsync};
assign wr_en = wr_req_4 & out_div;

SB_SPRAM256KA spram_0
  (
    .ADDRESS(ramadr[13:0]),
    .DATAIN(in_4_px),
    .MASKWREN(4'b1111),
    .WREN(wr_en),
    .CHIPSELECT(ram_cs[0]),
    .CLOCK(vga_ck),
    .STANDBY(1'b0),
    .SLEEP(1'b0),
    .POWEROFF(1'b1),
    .DATAOUT(ramdat_out_0)
  );

SB_SPRAM256KA spram_1
  (
    .ADDRESS(ramadr[13:0]),
    .DATAIN(in_4_px),
    .MASKWREN(4'b1111),
    .WREN(wr_en),
    .CHIPSELECT(ram_cs[1]),
    .CLOCK(vga_ck),
    .STANDBY(1'b0),
    .SLEEP(1'b0),
    .POWEROFF(1'b1),
    .DATAOUT(ramdat_out_1)
  );

  SB_SPRAM256KA spram_2
  (
    .ADDRESS(ramadr[13:0]),
    .DATAIN(in_4_px),
    .MASKWREN(4'b1111),
    .WREN(wr_en),
    .CHIPSELECT(ram_cs[2]),
    .CLOCK(vga_ck),
    .STANDBY(1'b0),
    .SLEEP(1'b0),
    .POWEROFF(1'b1),
    .DATAOUT(ramdat_out_2)
  );

SB_SPRAM256KA spram_3
  (
    .ADDRESS(ramadr[13:0]),
    .DATAIN(in_4_px),
    .MASKWREN(4'b1111),
    .WREN(wr_en),
    .CHIPSELECT(ram_cs[3]),
    .CLOCK(vga_ck),
    .STANDBY(1'b0),
    .SLEEP(1'b0),
    .POWEROFF(1'b1),
    .DATAOUT(ramdat_out_3)
  );

 `ifdef sim
  initial begin
  in_clk_div = 0;
  {in_cnt_h_4px,in_cnt_h_px} = 0;
  in_cnt_v = 0;
  in_3_px  = 0;
  in_4_px  = 0;
  in_sync  = 0;
  in_page  = 0;
  wr_req_1 = 0;
  wr_req_2 = 0;
  wr_req_3 = 0;
  wr_req_4 = 0;
  out_page = 1;
  out_4_px = 0;
  out_div  = 0;
  {out_cnt_h_4px,out_cnt_h_px} = 0;
  out_cnt_v = 0;
  
  end
 
 `endif
endmodule // top.v
