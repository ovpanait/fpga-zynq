set ip_name test_ip
set ip_repo_path "[pwd]/ip_repo"
set ip_path "[pwd]/ip_repo/$ip_name"

file mkdir "[pwd]/ip_repo"

create_project -part xc7z020clg400-1 $ip_name $ip_path

create_peripheral user.org user $ip_name 1.0 -dir $ip_path
add_peripheral_interface S00_AXIS -interface_mode slave -axi_type stream [ipx::find_open_core user.org:user:$ip_name:1.0]
add_peripheral_interface M00_AXIS -interface_mode master -axi_type stream [ipx::find_open_core user.org:user:$ip_name:1.0]
generate_peripheral [ipx::find_open_core user.org:user:$ip_name:1.0]
write_peripheral [ipx::find_open_core user.org:user:$ip_name:1.0]

# IP edit project
ipx::edit_ip_in_project -upgrade true -name edit_$ip_name -directory $ip_path $ip_path/[set ip_name]_1.0/component.xml

# Add hdl sources
remove_files {*}[glob $ip_path/[set ip_name]_1.0/hdl/*.v]
file delete {*}[glob $ip_path/[set ip_name]_1.0/hdl/*.v]
add_files [glob Sources/*.v] -copy_to $ip_path/[set ip_name]_1.0/hdl
add_files [glob -nocomplain Sources/*.vh] -quiet -copy_to $ip_path/[set ip_name]_1.0/hdl
set_property top $ip_name [current_fileset]

# Add testbench sources
# TODO

update_compile_order -fileset [current_fileset]
ipx::merge_project_changes files [ipx::current_core]
ipx::merge_project_changes hdl_parameters [ipx::current_core]

# Check for syntax errors
# If we don't do this here, it will generate subtle errors when running simulation
synth_design -rtl

#launch_runs synth_1 -jobs 8
#wait_on_run synth_1

set_property core_revision 1 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

#update_ip_catalog -rebuild
#update_ip_catalog -rebuild -repo_path /home/ovidiu/Xilinx/xilinx-projects-temp/test2/ip_repo/test_ip/test_ip_1.0

close_project -delete

# Close initial project
close_project -delete

exit


