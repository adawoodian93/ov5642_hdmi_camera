# Define project name and directory
set project_name "prj"
set project_dir "./$project_name"

# Set simulation time
#set_property -name {xsim.simulate.runtime} -value {0.5ms} -objects [get_filesets sim_1]

# Create and setup simulation
launch_simulation
run 0.5ms

# Modify the wave configuration
add_wave -radix bin      {{/tb_pixel_buffer/i_rst}}
add_wave -radix bin      {{/tb_pixel_buffer/i_cam_rst}}
add_wave -radix bin      {{/tb_pixel_buffer/i_init_done}}
add_wave -radix unsigned {{/tb_pixel_buffer/row_q}}
add_wave -radix unsigned {{/tb_pixel_buffer/col_q}}
add_wave -radix unsigned {{/tb_pixel_buffer/pclk_cnt_q}}

# Add a divider for pixel_buffer
add_wave_divider "Pixel Buffer"
add_wave -radix bin      {{/tb_pixel_buffer/i_hdmi_clk}}
add_wave -radix bin      {{/tb_pixel_buffer/i_pclk}}
add_wave -radix hex      {{/tb_pixel_buffer/i_pdata}}
add_wave -radix bin      {{/tb_pixel_buffer/i_vsync}}
add_wave -radix bin      {{/tb_pixel_buffer/i_href}}
add_wave -radix hex      {{/tb_pixel_buffer/o_rgb8}}
add_wave -radix bin      {{/tb_pixel_buffer/o_rgb8_valid}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_pbuffer_vsync_q}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_frame_valid_q}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_pixel_valid_q}}
add_wave -radix hex      {{/tb_pixel_buffer/cs_pixel_shift_reg_q}}
add_wave -radix hex      {{/tb_pixel_buffer/cs_d8_to_d16_toggle_q}}
add_wave -radix hex      {{/tb_pixel_buffer/cs_r_chan_8b_q}}
add_wave -radix hex      {{/tb_pixel_buffer/cs_g_chan_8b_q}}
add_wave -radix hex      {{/tb_pixel_buffer/cs_b_chan_8b_q}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_pixel_fifo_wren}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_pixel_fifo_rden}}
add_wave -radix hex      {{/tb_pixel_buffer/cs_pixel_fifo_dout}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_pixel_fifo_full}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_pixel_fifo_empty}}
add_wave -radix unsigned {{/tb_pixel_buffer/cs_rd_data_count}}
add_wave -radix unsigned {{/tb_pixel_buffer/cs_wr_data_count}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_wr_rst_busy}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_rd_rst_busy}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_rgb8_valid_q}}

# Add a divider for hdmi_out
add_wave_divider "HDMI Out"
add_wave -radix bin      {{/tb_pixel_buffer/i_serdes_clk}}
add_wave -radix hex      {{/tb_pixel_buffer/o_serial_tmds_data_p}}
add_wave -radix hex      {{/tb_pixel_buffer/o_serial_tmds_data_n}}
add_wave -radix bin      {{/tb_pixel_buffer/o_serial_tmds_clk_p}}
add_wave -radix bin      {{/tb_pixel_buffer/o_serial_tmds_clk_n}}
add_wave -radix bin      {{/tb_pixel_buffer/o_pixel_fifo_re}}
add_wave -radix unsigned {{/tb_pixel_buffer/cs_col_q}}
add_wave -radix unsigned {{/tb_pixel_buffer/cs_row_q}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_hsync_q}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_hdmi_vsync_q}}
add_wave -radix bin      {{/tb_pixel_buffer/cs_active_video_q}}
add_wave -radix hex      {{/tb_pixel_buffer/cs_tmds_rgb}}

# Add a divider for TB parameters
add_wave_divider "TB Parameters"
add_wave -radix unsigned {{/tb_pixel_buffer/FRAME_TIME}}
add_wave -radix unsigned {{/tb_pixel_buffer/FRAME_WIDTH}}
add_wave -radix unsigned {{/tb_pixel_buffer/FRAME_HEIGHT}}
add_wave -radix unsigned {{/tb_pixel_buffer/VSYNC_PERIOD}}
add_wave -radix unsigned {{/tb_pixel_buffer/VSYNC_LO_PRE_HREF_HI}}
add_wave -radix unsigned {{/tb_pixel_buffer/HSYNC_PERIOD}}

# Save the wave configuration
save_wave_config "$project_dir/$project_name.wcfg"