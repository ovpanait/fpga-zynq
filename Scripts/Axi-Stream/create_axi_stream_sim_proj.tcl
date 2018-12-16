set proj_name test_proj
set proj_path "[pwd]/$proj_name"

set top [lindex $argv 0]
set ip_name $top
set ip_path "[pwd]/ip_repo/$ip_name"

file mkdir $proj_path
create_project -part xc7z020clg400-1 $proj_name $proj_path

# Add ip
set_property ip_repo_paths $ip_path/[set ip_name]_1.0/ [current_project]
update_ip_catalog -rebuild

create_bd_design "design_1"
update_compile_order -fileset sources_1

# Add verification master
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi4stream_vip:1.1 axi4stream_vip_0
endgroup
set_property -dict [list CONFIG.TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells axi4stream_vip_0]
set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} CONFIG.TDATA_NUM_BYTES {4}] [get_bd_cells axi4stream_vip_0]

# Add verification slave
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi4stream_vip:1.1 axi4stream_vip_1
endgroup
set_property -dict [list CONFIG.TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells axi4stream_vip_1]
set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} CONFIG.TDATA_NUM_BYTES {4}] [get_bd_cells axi4stream_vip_1]

create_bd_cell -type ip -vlnv "user.org:user:$top:1.0" "[set top]_0"

# Create connections
connect_bd_intf_net [get_bd_intf_pins axi4stream_vip_0/M_AXIS] [get_bd_intf_pins [set top]_0/S00_AXIS]
connect_bd_intf_net [get_bd_intf_pins [set top]_0/M00_AXIS] [get_bd_intf_pins axi4stream_vip_1/S_AXIS]

startgroup
make_bd_pins_external  [get_bd_cells axi4stream_vip_0]
make_bd_intf_pins_external  [get_bd_cells axi4stream_vip_0]
endgroup
set_property name aclk [get_bd_ports aclk_0]

make_bd_pins_external  [get_bd_pins axi4stream_vip_0/aresetn]
set_property name aresetn [get_bd_ports aresetn_0]

connect_bd_net [get_bd_pins [set top]_0/m00_axis_aresetn] [get_bd_pins [set top]_0/s00_axis_aresetn]
connect_bd_net [get_bd_ports aresetn] [get_bd_pins [set top]_0/m00_axis_aresetn]
connect_bd_net [get_bd_ports aresetn] [get_bd_pins axi4stream_vip_1/aresetn]

connect_bd_net [get_bd_pins [set top]_0/s00_axis_aclk] [get_bd_pins [set top]_0/m00_axis_aclk]
connect_bd_net [get_bd_ports aclk] [get_bd_pins [set top]_0/m00_axis_aclk]
connect_bd_net [get_bd_ports aclk] [get_bd_pins axi4stream_vip_1/aclk]

validate_bd_design -force

# Create verilog wrapper
make_wrapper -files [get_files $proj_path/[set proj_name].srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse $proj_path/[set proj_name].srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v

generate_target all [get_files $proj_path/[set proj_name].srcs/sources_1/bd/design_1/design_1.bd]
catch { config_ip_cache -export [get_ips -all design_1_axi4stream_vip_0_0] }
catch { config_ip_cache -export [get_ips -all design_1_axi4stream_vip_1_0] }
export_ip_user_files -of_objects [get_files $proj_path/[set proj_name].srcs/sources_1/bd/design_1/design_1.bd] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] [get_files $proj_path/[set proj_name].srcs/sources_1/bd/design_1/design_1.bd]]
launch_runs -jobs 8 {design_1_axi4stream_vip_0_0_synth_1 design_1_axi4stream_vip_1_0_synth_1}

# Simulation
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset [get_filesets sim_1] -norecurse [pwd]/tb/tb_main.sv

foreach ip [get_ips] {
	add_files -fileset [get_filesets sim_1] [get_files -compile_order sources -used_in simulation -of [get_files [set ip].xci]]
}

update_compile_order -fileset sim_1
set_property top tb_main [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

get_files -compile_order sources -used_in simulation

set outputDir ./outputs
file mkdir $outputDir

export_simulation \
    -simulator xsim \
    -ip_user_files_dir $proj_path/[set proj_name].ip_user_files \
    -ipstatic_source_dir $proj_path/[set proj_name].ip_user_files/ipstatic \
    -use_ip_compiled_libs \
    -force \
    -directory "$outputDir/export_sim" \
    -include "$env(INCLUDE_DIR)"

close_project
exit
