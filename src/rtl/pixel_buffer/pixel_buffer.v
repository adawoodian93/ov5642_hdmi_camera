/*TODO: 
	- Add pixel valid output signal so that downstream TMDS encoder does not encode stale
	  pixel values while the pixel FIFO is empty. 
	  ***DONE***
	 
	- Possible will need to buffer at least 1 line of video data before reading out FIFO
	  as to not underflow downstream logic so that stale pixel data does not propagate 
	  the system.
*/

`timescale 1ns/1ps
module pixel_buffer (
  // System Ports
  input wire         i_hdmi_clk, //74.25MHz
  input wire         i_rst,
  // input wire         i_cam_rst, //Cannot synchronize reset to i_pclk
  input wire         i_init_done, //Synchronous to 100MHz clock
  
  // Sensor Ports
  input wire         i_pclk,  //148.5MHz
  input wire [7:0]   i_pdata, //RGB565; {R[4:0], G[5:3]} -> {G[2:0], B[4:0]}
  input wire         i_vsync,
  input wire         i_href,

  // Pixel2RGB Ports
  output wire [23:0] o_rgb8,
  // output wire [7:0]  o_r8,
  // output wire [7:0]  o_g8,
  // output wire [7:0]  o_b8,
  output wire        o_rgb8_valid,
  
  // ILA/TB Ports
  output wire        cs_vsync_q,
  output wire        cs_frame_valid_q,
  output wire        cs_pixel_valid_q,
  output wire [15:0] cs_pixel_shift_reg_q,
  output wire        cs_d8_to_d16_toggle_q,
  output wire [7:0]  cs_r_chan_8b_q,
  output wire [7:0]  cs_g_chan_8b_q,
  output wire [7:0]  cs_b_chan_8b_q,
  output wire        cs_pixel_fifo_wren,
  output wire        cs_pixel_fifo_rden,
  output wire [15:0] cs_pixel_fifo_dout,
  output wire        cs_pixel_fifo_full,
  output wire        cs_pixel_fifo_empty,
  output wire [4:0]  cs_rd_data_count,
  output wire [4:0]  cs_wr_data_count,
  output wire        cs_wr_rst_busy,
  output wire        cs_rd_rst_busy,
  output wire        cs_rgb8_valid_q
);

  reg        vsync_q;
  reg        frame_valid_q;
  reg        pixel_valid_q;
  reg [15:0] pixel_shift_reg_q;
  reg        d8_to_d16_toggle_q;
  reg [7:0]  r_chan_8b_q;
  reg [7:0]  g_chan_8b_q;
  reg [7:0]  b_chan_8b_q;
  reg        rgb8_valid_q;
  
  wire        pixel_fifo_wren;
  wire        pixel_fifo_rden;
  wire [15:0] pixel_fifo_dout;
  wire        pixel_fifo_full;
  wire        pixel_fifo_empty;
  wire [8:0]  rd_data_count;
  wire [8:0]  wr_data_count;
  wire        wr_rst_busy;
  wire        rd_rst_busy;
  wire        vsync_negedge;
  wire        vsync_posedge;
  
  // 256-deep
  fifo_16 i_pixel_fifo (
    .rst          (i_rst),         // input wire rst
    .wr_clk       (i_pclk),            // input wire wr_clk
    .rd_clk       (i_hdmi_clk),        // input wire rd_clk
    .din          (pixel_shift_reg_q), // input wire [15 : 0] din
    .wr_en        (pixel_fifo_wren),   // input wire wr_en
    .rd_en        (pixel_fifo_rden),   // input wire rd_en
    .dout         (pixel_fifo_dout),   // output wire [15 : 0] dout
    .full         (pixel_fifo_full),   // output wire full
    .empty        (pixel_fifo_empty),  // output wire empty
    .rd_data_count(rd_data_count),     // output wire [8 : 0] rd_data_count
    .wr_data_count(wr_data_count),     // output wire [8 : 0] wr_data_count
    .wr_rst_busy  (wr_rst_busy),       // output wire wr_rst_busy
    .rd_rst_busy  (rd_rst_busy)        // output wire rd_rst_busy
  );
  
  assign pixel_fifo_wren = pixel_valid_q && (!pixel_fifo_full);
  assign pixel_fifo_rden = /*i_pixel_fifo_re &&*/ (!pixel_fifo_empty);
  
  always @(posedge i_pclk or posedge i_rst) begin
    if (i_rst)
      vsync_q <= 1'b0;
    else
      vsync_q <= i_vsync;
  end
  
  assign vsync_negedge = vsync_q && (!i_vsync);
  assign vsync_posedge = i_vsync && (!vsync_q);

  always @(posedge i_pclk or posedge i_rst) begin
    if (i_rst) 
      frame_valid_q <= 1'b0;
    else if (vsync_negedge && i_init_done)
      frame_valid_q <= 1'b1;
    else if (vsync_posedge && i_init_done)
      frame_valid_q <= 1'b0;
  end
  
  //Shifts each byte of 2-byte pixel into register asserting a valid signal
  //when 2-byte pixel is present in the register effectively reducing 
  //pixel clock down to 74.25MHz
  //pixel_shift_reg_q = {R[4:0], G[5:0], B[4:0]}
  always @(posedge i_pclk or posedge i_rst) begin
    if (i_rst) begin
      pixel_valid_q <= 1'b0;
      pixel_shift_reg_q <= 16'b0;
      d8_to_d16_toggle_q <= 1'b0;
    end else if (frame_valid_q && i_href) begin
      if (!d8_to_d16_toggle_q) begin
        pixel_valid_q <= 1'b0;
        pixel_shift_reg_q <= {8'b0, i_pdata};
        d8_to_d16_toggle_q <= 1'b1;
      end else begin
        pixel_valid_q <= 1'b1;
        pixel_shift_reg_q <= {pixel_shift_reg_q[7:0], i_pdata};
        d8_to_d16_toggle_q <= 1'b0;
      end
    end else
      pixel_valid_q <= 1'b0;
  end
  
  //Pixel2RGB Logic
  always @(posedge i_hdmi_clk) begin
    if (i_rst) begin
      r_chan_8b_q <= 8'b0;
      g_chan_8b_q <= 8'b0;
      b_chan_8b_q <= 8'b0;
      rgb8_valid_q <= 1'b0;
    end else if (!pixel_fifo_empty) begin
      r_chan_8b_q <= (255*pixel_fifo_dout[15:11])/31; //pixel_fifo_dout[15:11];
      g_chan_8b_q <= (255*pixel_fifo_dout[10:5])/63; //pixel_fifo_dout[10:5];
      b_chan_8b_q <= (255*pixel_fifo_dout[4:0])/31; //pixel_fifo_dout[4:0];
      rgb8_valid_q <= 1'b1;
	end else
      rgb8_valid_q <= 1'b0;
  end
  
  // Output Assignments
  // assign o_r8 = r_chan_8b_q; //(255*r_chan_q)/31;
  // assign o_g8 = g_chan_8b_q; //(255*g_chan_q)/63;
  // assign o_b8 = b_chan_8b_q; //(255*b_chan_q)/31;
  assign o_rgb8 = {r_chan_8b_q, g_chan_8b_q, b_chan_8b_q};
  assign o_rgb8_valid = rgb8_valid_q;
  
  //ILA/TB Assignments
  assign cs_vsync_q            = vsync_q           ;
  assign cs_frame_valid_q      = frame_valid_q     ;
  assign cs_pixel_valid_q      = pixel_valid_q     ;
  assign cs_pixel_shift_reg_q  = pixel_shift_reg_q ;
  assign cs_d8_to_d16_toggle_q = d8_to_d16_toggle_q;
  assign cs_r_chan_8b_q        = r_chan_8b_q       ;
  assign cs_g_chan_8b_q        = g_chan_8b_q       ;
  assign cs_b_chan_8b_q        = b_chan_8b_q       ;
  assign cs_pixel_fifo_wren    = pixel_fifo_wren   ;
  assign cs_pixel_fifo_rden    = pixel_fifo_rden   ;
  assign cs_pixel_fifo_dout    = pixel_fifo_dout   ;
  assign cs_pixel_fifo_full    = pixel_fifo_full   ;
  assign cs_pixel_fifo_empty   = pixel_fifo_empty  ;
  assign cs_rd_data_count      = rd_data_count     ;
  assign cs_wr_data_count      = wr_data_count     ;
  assign cs_wr_rst_busy        = wr_rst_busy       ;
  assign cs_rd_rst_busy        = rd_rst_busy       ;
  assign cs_rgb8_valid_q       = rgb8_valid_q      ;
   
endmodule
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  