# Define project name and directory
set project_name "prj"
set project_dir "./$project_name"

# Set simulation time
#set_property -name {xsim.simulate.runtime} -value {0.5ms} -objects [get_filesets sim_1]

# Create and setup simulation
launch_simulation
run 200us

# Modify the wave configuration
add_wave -radix bin      {{/tb_sccb_top/i_clk}}
add_wave -radix bin      {{/tb_sccb_top/i_rst}}
add_wave -radix bin      {{/tb_sccb_top/i_start_init}}

# Add a divider for sccb_top
add_wave_divider "SCCB Top"
add_wave -radix bin      {{/tb_sccb_top/i_siod_in}}
add_wave -radix bin      {{/tb_sccb_top/o_sioc}}
add_wave -radix bin      {{/tb_sccb_top/o_siod_out}}
add_wave -radix bin      {{/tb_sccb_top/o_siod_oe}}
add_wave -radix bin      {{/tb_sccb_top/o_done_led}}
add_wave -radix bin      {{/tb_sccb_top/o_err_led}}
add_wave -radix hex      {{/tb_sccb_top/cs_tx_data_q}}
add_wave -radix bin      {{/tb_sccb_top/cs_start}}
add_wave -radix bin      {{/tb_sccb_top/cs_stop}}
add_wave -radix unsigned {{/tb_sccb_top/cs_reg_idx_q}}
add_wave -radix hex      {{/tb_sccb_top/cs_byte_cnt_q_mst}}
add_wave -radix unsigned {{/tb_sccb_top/cs_err_cnt_q}}
add_wave -radix hex      {{/tb_sccb_top/cs_update_tx_byte}}
add_wave -radix hex      {{/tb_sccb_top/cs_update_rx_byte}}
add_wave -radix bin      {{/tb_sccb_top/cs_init_done}}
add_wave -radix bin      {{/tb_sccb_top/cs_inc_addr}}
add_wave -radix hex      {{/tb_sccb_top/cs_pstate_q_top}}
add_wave -radix hex      {{/tb_sccb_top/cs_rx_data}}
add_wave -radix bin      {{/tb_sccb_top/cs_tx_ready}}
add_wave -radix bin      {{/tb_sccb_top/cs_rx_ready}}
add_wave -radix unsigned {{/tb_sccb_top/cs_reg_addr}}
add_wave -radix hex      {{/tb_sccb_top/cs_reg_data}}
add_wave -radix bin      {{/tb_sccb_top/cs_verify_reg}}
add_wave -radix bin      {{/tb_sccb_top/cs_ack}}

# Add a divider for sccb_core
add_wave_divider "SCCB Core"
add_wave -radix bin      {{/tb_sccb_top/cs_sioc_q_mst}}
add_wave -radix bin      {{/tb_sccb_top/cs_siod_q}}
add_wave -radix hex      {{/tb_sccb_top/cs_tx_byte_q}}
add_wave -radix hex      {{/tb_sccb_top/cs_rx_byte_q}}
add_wave -radix unsigned {{/tb_sccb_top/cs_bit_in_byte_q}}
add_wave -radix hex      {{/tb_sccb_top/cs_pstate_q_core}}
add_wave -radix bin      {{/tb_sccb_top/cs_update_index}}
add_wave -radix bin      {{/tb_sccb_top/cs_update_verify}}
add_wave -radix bin      {{/tb_sccb_top/cs_verify_reg_q}}
add_wave -radix bin      {{/tb_sccb_top/cs_sioc_lo_mst}}
add_wave -radix bin      {{/tb_sccb_top/cs_sioc_hi_mst}}
add_wave -radix unsigned {{/tb_sccb_top/cs_clk_cnt_q}}

# Add a divider for sccb_slave
add_wave_divider "SCCB Slave"
add_wave -radix bin      {{/tb_sccb_top/cs_siod_in_q}}
add_wave -radix bin      {{/tb_sccb_top/cs_sioc_q_slv}}
add_wave -radix unsigned {{/tb_sccb_top/cs_sioc_hi_cnt_q}}
add_wave -radix unsigned {{/tb_sccb_top/cs_sioc_lo_cnt_q}}
add_wave -radix hex      {{/tb_sccb_top/cs_id_addr_q}}
add_wave -radix unsigned {{/tb_sccb_top/cs_id_addr_bit_q}}
add_wave -radix unsigned {{/tb_sccb_top/cs_bit_cnt_q}}
add_wave -radix unsigned {{/tb_sccb_top/cs_byte_cnt_q_slv}}
add_wave -radix hex      {{/tb_sccb_top/cs_wr_data_q}}
add_wave -radix unsigned {{/tb_sccb_top/cs_wr_data_cnt_q}}
add_wave -radix hex      {{/tb_sccb_top/cs_pstate_q}}
add_wave -radix hex      {{/tb_sccb_top/cs_nstate}}
add_wave -radix bin      {{/tb_sccb_top/cs_siod_fedge}}
add_wave -radix bin      {{/tb_sccb_top/cs_siod_redge}}
add_wave -radix bin      {{/tb_sccb_top/cs_sioc_redge}}
add_wave -radix bin      {{/tb_sccb_top/cs_sioc_lo_slv}}
add_wave -radix bin      {{/tb_sccb_top/cs_sioc_hi_slv}}

# Save the wave configuration
save_wave_config "$project_dir/$project_name.wcfg"