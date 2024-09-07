# Define project name and directory
set project_name "prj"
set project_dir "./$project_name"

# Define the top module
set top_module "tb_pixel_buffer"

# Define the directories where RTL and IP files are located
set rtl_dir "../../src/rtl" ;# Replace with the actual path to your RTL files
set ip_dir "../../src/ip"   ;# Replace with the actual path to your IP files

# Check if the project directory exists and delete it if it does
if {[file exists $project_dir]} {
    puts "Deleting existing project directory: $project_dir"
    file delete -force $project_dir
}

# Define HDL source files with full paths
set rtl_files [list \
    "$rtl_dir/hdmi_out/hdmi_out.v" \
	"$rtl_dir/hdmi_out/output_serdes.v" \
	"$rtl_dir/hdmi_out/tmds_encoder.v" \
	"$rtl_dir/pixel_buffer/pixel_buffer.v" \
	"$rtl_dir/pixel_buffer/tb_pixel_buffer.v" 
]

# Define IP core files (.xci) with full paths
set ip_files [list \
    "$ip_dir/fifo_16/fifo_16.xci"
]

# Create a new project
create_project $project_name $project_dir -part xc7a200tsbg484-1

# Add the HDL files to the project
foreach file $rtl_files {
    add_files $file
}

# Add the IP cores to the project
foreach ip $ip_files {
    add_files $ip
}
# foreach ip $ip_files {
    # import_ip $ip
    # generate_target {instantiation_template} [get_files $ip]
    # generate_target {synthesis simulation} [get_files $ip]
# }

# Set the top module
set_property top $top_module [current_fileset -simset]
