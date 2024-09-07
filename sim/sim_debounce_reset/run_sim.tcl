# Define project name and directory
set project_name "prj"
set project_dir "./$project_name"

# Set simulation time
#set_property -name {xsim.simulate.runtime} -value {0.5ms} -objects [get_filesets sim_1]

# Create and setup simulation
launch_simulation
run 1.5us

# Modify the wave configuration
add_wave -radix bin {{/tb_debounce_reset/i_clk}}
add_wave -radix bin {{/tb_debounce_reset/i_pb}}
add_wave -radix bin {{/tb_debounce_reset/o_pb_clean}}
add_wave -radix bin {{/tb_debounce_reset/o_sync_reset}}
add_wave -radix bin {{/tb_debounce_reset/cs_clk_count_q}}
add_wave -radix bin {{/tb_debounce_reset/cs_clk_en_q}}
add_wave -radix bin {{/tb_debounce_reset/cs_pb_q1}}
add_wave -radix bin {{/tb_debounce_reset/cs_pb_q2}}
add_wave -radix bin {{/tb_debounce_reset/cs_pb_q3}}

# Save the wave configuration
save_wave_config "$project_dir/$project_name.wcfg"