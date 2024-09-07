# Define project name and directory
set project_name "prj"
set project_dir "./$project_name"

# Define the top module
set top_module "tb_sccb_top"

# Define the directories where RTL and IP files are located
set rtl_dir "../../src/rtl" ;# Replace with the actual path to your RTL files

# Check if the project directory exists and delete it if it does
if {[file exists $project_dir]} {
    puts "Deleting existing project directory: $project_dir"
    file delete -force $project_dir
}

# Define HDL source files with full paths
set rtl_files [list \
    "$rtl_dir/sccb_top/ov5642_init_regs.v" \
	"$rtl_dir/sccb_top/sccb_core.v" \
	"$rtl_dir/sccb_top/sccb_slave.v" \
	"$rtl_dir/sccb_top/sccb_top.v" \
	"$rtl_dir/sccb_top/tb_sccb_top.v"
]

# Create a new project
create_project $project_name $project_dir -part xc7a200tsbg484-1

# Add the HDL files to the project
foreach file $rtl_files {
    add_files $file
}

# Set the top module
set_property top $top_module [current_fileset -simset]
