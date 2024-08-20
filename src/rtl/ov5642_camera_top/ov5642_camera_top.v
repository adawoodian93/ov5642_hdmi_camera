`timescale 1ns / 1ps
module ov5642_camera_top (
	// System Ports
	input wire i_sys_clk, //100MHz clock; Pin Y9
	input wire i_sys_rst, //Push-Button???
	
	// Digital Video Ports (DVP)
	input wire        i_dvp_vsync,
	input wire        i_dvp_href,
	input wire        i_dvp_pclk,  //Pixel clock 148.5MHz
	input wire  [7:0] i_dvp_pdata, //8-bit pixel data
	output wire       o_dvp_xclk,  //External master clock into sensor
	
	// SCCB Ports
	inout wire  io_sccb_data,
	output wire o_sccb_scl,
	output wire o_sccb_done,  //LEDs
	output wire o_sccb_error, //LEDs
	
	// HDMI Ports ([2:0] = {r, g, b})
	output wire [2:0] o_tmds_rgb_data_p,
	output wire [2:0] o_tmds_rgb_data_n,
	output wire       o_tmds_clk_p,
	output wire       o_tmds_clk_n
);

	wire        clk_74_25;
	wire        clk_371_25;
	wire        clk_24_75;
	wire        sync_rst_74_25;
	wire        sync_rst_100;
	wire        init_done;
	wire        siod_in, siod_out, siod_oe;
	wire [23:0] rgb8;
	
	clk_wiz_0 i_clock_gen (
		.clk_out1(clk_74_25),   
		.clk_out2(clk_371_25),   
		.clk_out3(clk_24_75),   
		.reset   (clean_rst_100), 
		.locked  (),
		.clk_in1 (i_sys_clk)
	);

	pixel_buffer i_pixel_buffer (
		.i_hdmi_clk           (clk_74_25),
		.i_rst                (clean_rst_74_25),
		//.i_cam_rst            (),
		.i_init_done          (init_done),
		.i_pclk               (i_dvp_pclk),
		.i_pdata              (i_dvp_pdata),
		.i_vsync              (i_dvp_vsync),
		.i_href               (i_dvp_href),
		.o_rgb8               (rgb8),
		.o_rgb8_valid         (),
		// .o_r8                 (),
		// .o_g8                 (),
		// .o_b8                 (),
		.cs_vsync_q           (),
		.cs_frame_valid_q     (),
		.cs_pixel_valid_q     (),
		.cs_pixel_shift_reg_q (),
		.cs_d8_to_d16_toggle_q(),
		.cs_r_chan_q          (),
		.cs_g_chan_q          (),
		.cs_b_chan_q          (),
		.cs_pixel_fifo_wren   (),
		.cs_pixel_fifo_rden   (),
		.cs_pixel_fifo_dout   (),
		.cs_pixel_fifo_full   (),
		.cs_pixel_fifo_empty  (),
		.cs_rd_data_count     (),
		.cs_wr_data_count     (),
		.cs_wr_rst_busy       (),
		.cs_rd_rst_busy       ()
	);
	
	iobuf i_sccb_iobuf (
		.O(siod_in),
		.IO(io_sccb_data),
		.I(siod_out),
		.T(siod_oe)
	);
	
	sccb_top i_sccb_comm (
		i_clk             (i_sys_clk),
		i_rst             (clean_rst_100),
		o_sioc            (o_sccb_scl),
		i_siod_in         (siod_in),
		o_siod_out        (siod_out),
		o_siod_oe         (siod_oe),
		o_done            (o_sccb_done),
		o_err             (o_sccb_error),
		cs_tx_data_q      (),
		cs_start          (),
		cs_stop           (),
		cs_reg_idx_q      (),
		cs_byte_cnt_q     (),
		cs_err_cnt_q      (),
		cs_update_tx_byte (),
		cs_update_rx_byte (),
		cs_init_done_q    (),
		cs_inc_addr       (),
		cs_pstate_q_top   (),
		cs_rx_data        (),
		cs_tx_ready       (),
		cs_rx_ready       (),
		cs_reg_addr       (),
		cs_reg_data       (),
		cs_verify_reg     (),
		cs_ack            (),
		cs_sioc_q         (),
		cs_siod_q         (),
		cs_tx_byte_q      (),
		cs_rx_byte_q      (),
		cs_bit_in_byte_q  (),
		cs_pstate_q_core  (),
		cs_update_index   (),
		cs_update_verify  (),
		cs_verify_reg_q   (),
		cs_sioc_lo        (),
		cs_sioc_hi        (),
		cs_clk_cnt_q      (),
		cs_start_clk_cnt_q()
	);
	
	hdmi_out i_hdmi_interface (
		.i_clk_74_25         (clk_74_25        ),
		.i_clk_371_25        (clk_371_25       ),
		.i_rst               (clean_rst_74_25  ),
		.i_rgb8              (rgb8             ),
		.o_serial_tmds_data_p(o_tmds_rgb_data_p),
		.o_serial_tmds_data_n(o_tmds_rgb_data_n),
		.o_serial_tmds_clk_p (o_tmds_clk_p     ),	
		.o_serial_tmds_clk_n (o_tmds_clk_n     ),	
	);
	
	debounce i_clean_rst_74_25 (
		.i_clk         (clk_74_25),
		.i_pb          (i_sys_rst),
		.o_pb_clean    (clean_rst_74_25),
		.cs_pb_q1      (),
		.cs_pb_q2      (),
		.cs_pb_q3      (),
		.cs_clk_en_q   (),
		.cs_clk_count_q()
	);
	
	debounce i_clean_rst_100 (
		.i_clk         (i_sys_clk),
		.i_pb          (i_sys_rst),
		.o_pb_clean    (clean_rst_100),
		.cs_pb_q1      (),
		.cs_pb_q2      (),
		.cs_pb_q3      (),
		.cs_clk_en_q   (),
		.cs_clk_count_q()
	);
	
	// aasd_reset i_sync_rst_74_25 (
		// .i_clk      (clk_74_25),
		// .i_async_rst(i_sys_rst),
		// .o_sync_rst (sync_rst_74_25),
	// );
	
	// aasd_reset i_sync_rst_100 (
		// .i_clk      (i_sys_clk),
		// .i_async_rst(i_sys_rst),
		// .o_sync_rst (sync_rst_100),
	// );
	
endmodule
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	