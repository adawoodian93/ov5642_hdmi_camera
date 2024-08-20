`timescale 1ns / 1ps
module tb_pixel_buffer ();

    // DUT Input 
	reg         i_hdmi_clk;
	reg         i_rst;
	reg         i_cam_rst;
	reg         i_init_done;
	reg         i_pclk;
	reg [7:0]   i_pdata;
	reg         i_vsync;
	reg         i_href;
	
	// wire [7:0]  o_r8;
	// wire [7:0]  o_g8;
	// wire [7:0]  o_b8;
	wire [23:0] o_rgb8;
	wire        o_rgb8_valid;
	wire        cs_vsync_q;
	wire        cs_frame_valid_q;
	wire        cs_pixel_valid_q;
	wire [15:0] cs_pixel_shift_reg_q;
	wire        cs_d8_to_d16_toggle_q;
	wire [7:0]  cs_r_chan_8b_q;
	wire [7:0]  cs_g_chan_8b_q;
	wire [7:0]  cs_b_chan_8b_q;
	wire        cs_pixel_fifo_wren;
	wire        cs_pixel_fifo_rden;
	wire [15:0] cs_pixel_fifo_dout;
	wire        cs_pixel_fifo_full;
	wire        cs_pixel_fifo_empty;
	wire [4:0]  cs_rd_data_count;
	wire [4:0]  cs_wr_data_count;
	wire        cs_wr_rst_busy;
	wire        cs_rd_rst_busy; 
	wire        cs_rgb8_valid_q;
	
	// TB Signals
	reg [7:0] row_q;
	reg [7:0] col_q;
	
	// Clock and reset generation
	initial i_hdmi_clk = 1'b0;
	always #6.734 i_hdmi_clk = !i_hdmi_clk;
	
	initial i_pclk = 0;
	always #3.367 i_pclk = !i_pclk;
	
	initial i_rst = 1'b1;
	always #134.68 i_rst = 1'b0;
	
	initial i_cam_rst = 1'b1;
	always #67.34 i_cam_rst = 1'b0;
	
	// DUT
	pixel_buffer DUT (
		.i_hdmi_clk           (i_hdmi_clk           ),
		.i_rst                (i_rst                ),
		.i_cam_rst            (i_cam_rst            ),
		.i_init_done          (i_init_done          ),
		.i_pclk               (i_pclk               ),
		.i_pdata              (i_pdata              ),
		.i_vsync              (i_vsync              ),
		.i_href               (i_href               ),
		// .o_r8                 (o_r8                 ),
		// .o_g8                 (o_g8                 ),
		// .o_b8                 (o_b8                 ),
		.o_rgb8               (o_rgb8               ),
		.o_rgb8_valid         (o_rgb8_valid         ),
		.cs_vsync_q           (cs_vsync_q           ),
		.cs_frame_valid_q     (cs_frame_valid_q     ),
		.cs_pixel_valid_q     (cs_pixel_valid_q     ),
		.cs_pixel_shift_reg_q (cs_pixel_shift_reg_q ),
		.cs_d8_to_d16_toggle_q(cs_d8_to_d16_toggle_q),
		.cs_r_chan_8b_q       (cs_r_chan_8b_q       ),
		.cs_g_chan_8b_q       (cs_g_chan_8b_q       ),
		.cs_b_chan_8b_q       (cs_b_chan_8b_q       ),
		.cs_pixel_fifo_wren   (cs_pixel_fifo_wren   ),
		.cs_pixel_fifo_rden   (cs_pixel_fifo_rden   ),
		.cs_pixel_fifo_dout   (cs_pixel_fifo_dout   ),
		.cs_pixel_fifo_full   (cs_pixel_fifo_full   ),
		.cs_pixel_fifo_empty  (cs_pixel_fifo_empty  ),
		.cs_rd_data_count     (cs_rd_data_count     ),
		.cs_wr_data_count     (cs_wr_data_count     ),
		.cs_wr_rst_busy       (cs_wr_rst_busy       ),
		.cs_rd_rst_busy       (cs_rd_rst_busy       ),
		.cs_rgb8_valid_q      (cs_rgb8_valid_q      )
	);
    
    // Stimuli Generation
    initial i_init_done = 1'b0;
    always #100 i_init_done = 1'b1;
	
	always @(posedge i_pclk or posedge i_cam_rst) begin
		if (i_cam_rst) begin
			row_q <= 0;
			col_q <= 0;
		end else begin
			col_q <= col_q + 1;
			if (col_q == 255)
				row_q <= row_q + 1;
		end
	end
    
    always @(posedge i_pclk or posedge i_cam_rst) begin
		if (i_cam_rst)
			i_vsync <= 1'b0;
		else if ((row_q == 0) && (col_q == 0))
			i_vsync <= 1'b1;
		else if ((row_q == 3) && (col_q == 255))
			i_vsync <= 1'b0;
	end
	
	always @(posedge i_pclk or posedge i_cam_rst) begin
		if (i_cam_rst)
			i_href <= 1'b0;
		else if ((row_q > 3) && (col_q < 250)) //5 clks for hsync
			i_href <= 1'b1;
		else
			i_href <= 1'b0;
	end
	
	always @(posedge i_pclk or posedge i_cam_rst) begin
		if (i_cam_rst) begin
			i_pdata <= 16'h0;
		end else if (i_href) begin
			i_pdata <= i_pdata + 1;
		end
	end
	
endmodule
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
        
        