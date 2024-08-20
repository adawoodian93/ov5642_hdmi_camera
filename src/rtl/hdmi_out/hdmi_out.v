`timescale 1ns / 1ps
module hdmi_out (
	// System Ports
	input wire i_clk_74_25,
	input wire i_clk_371_25,
	input wire i_rst,
	
	// Pixel Buffer Ports
	input wire [23:0] i_rgb8,
	// input wire [7:0] i_r8,
	// input wire [7:0] i_g8,
	// input wire [7:0] i_b8,
	// input wire       i_rgb8_valid,
	
	// Serialized TMDS Ports
	output wire [2:0] o_serial_tmds_data_p,
	output wire [2:0] o_serial_tmds_data_n,
	output wire       o_serial_tmds_clk_p,
	output wire       o_serial_tmds_clk_n
);

	(* MARK_DEBUG = "TRUE" *) reg [11:0] col_q;
	(* MARK_DEBUG = "TRUE" *) reg [10:0] row_q;
	(* MARK_DEBUG = "TRUE" *) reg        hsync_q;
	(* MARK_DEBUG = "TRUE" *) reg        vsync_q;
	(* MARK_DEBUG = "TRUE" *) reg        active_video_q;
	
	(* MARK_DEBUG = "TRUE" *) wire [1:0]  tmds_ctrl [0:2];
	(* MARK_DEBUG = "TRUE" *) wire [29:0] tmds_rgb;
	
	//Continuous assignments
	assign tmds_ctrl[0] = {vsync_q, hsync_q};
	assign tmds_ctrl[1] = 2'b0;
	assign tmds_ctrl[2] = 2'b0;

	always @(posedge i_clk_74_25) begin
		if (i_rst) begin
			col_q <= 0;
			row_q <= 0;
			hsync_q <= 1'b0;
			vsync_q <= 1'b0;
			active_video_q <= 1'b0;
		end else /*if (i_rgb8_valid)*/ begin
			col_q <= col_q + 1;
			hsync_q <= ((col_q >= 2008) && (col_q < 2052)); //hsync period = 44 pixels after the front porch of 88 pixels (2008 = 1920 + 88)
			vsync_q <= ((row_q >= 1084) && (row_q < 1089)); //vsync period = 5 pixels after the front porch of 4 pixels (1084 = 1080 + 4)
			active_video_q <= ((col_q < 1920) && (row_q < 1080));
			if (col_q == 2199) begin
				col_q <= 0;
				row_q <= (row_q == 1124) ? 0 : row_q + 1;
			end
		end
	end
	
	genvar idx;
	
	//idx 2 = red; idx 1 = green; idx 0 = blue
	generate
		for (idx = 0; idx < 3; idx = idx + 1) begin
			tmds_encoder i_tmds_encode_rgb (
				.clk     (i_clk_74_25           ), 
				.data    (i_rgb8[idx*8 +: 8]    ), 
				.ctrl    (tmds_ctrl[idx]        ), 
				.sel     (active_video_q        ), 
				.TMDS_out(tmds_rgb[idx*10 +: 10])
			);
			
			output_serdes i_data_serializer (
				.i_pdata_clk(i_clk_74_25              ),
				.i_sdata_clk(i_clk_371_25             ),
				.i_rst      (i_rst                    ),
				.i_pdata    (tmds_rgb[idx*10 +: 10]   ),
				.o_sdata_p  (o_serial_tmds_data_p[idx]),
				.o_sdata_n  (o_serial_tmds_data_n[idx])
			);
		end
	endgenerate
	
	//Or simply output TMDS clock using OBUFDS. HDMI pixel clock of 74.25MHz
	//should be slow enough to be able to be forwarded via OBUFDS.
	output_serdes i_clk_serializer (
		.i_pdata_clk(i_clk_74_25        ),
		.i_sdata_clk(i_clk_371_25       ),
		.i_rst      (i_rst              ),
		.i_pdata    (10'b1111100000     ),
		.o_sdata_p  (o_serial_tmds_clk_p),
		.o_sdata_n  (o_serial_tmds_clk_n)
	);
	
	/*
	tmds_encoder i_tmds_encode_r (
		.clk(i_clk_74_25), 
		.data(i_r8), 
		.ctrl({0,0}), 
		.sel(active_video_q), 
		.TMDS_out(o_tmds_red)
	);
	
	tmds_encoder i_tmds_encode_g (
		.clk(i_clk_74_25), 
		.data(i_g8), 
		.ctrl({0,0}), 
		.sel(active_video_q), 
		.TMDS_out(o_tmds_green)
	);
	
	tmds_encoder i_tmds_encode_b (
		.clk(i_clk_74_25), 
		.data(i_b8), 
		.ctrl({vsync_q, hsync_q}), 
		.sel(active_video_q), 
		.TMDS_out(o_tmds_blue)
	);
	*/
	
endmodule