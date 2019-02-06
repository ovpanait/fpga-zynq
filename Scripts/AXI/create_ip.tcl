source $env(TCL_INCLUDE)/debug.tcl

# Command line parameters
set ip_name [lindex $argv 0]
set axi_type [lindex $argv 1]
set int_type [lindex $argv 2]

# IP info
set ip_repo_path "[pwd]/ip_repo"
set ip_path "[pwd]/ip_repo/$ip_name"
file mkdir "[pwd]/ip_repo"

set interface_name_slave [concat "S00_AXI" [expr {$axi_type == "stream" ? "S" : ""}]]
set interface_name_master [concat "M00_AXI" [expr {$axi_type == "stream" ? "S" : ""}]]

create_project -part xc7z020clg400-1 $ip_name $ip_path

# Create peripheral
create_peripheral user.org user $ip_name 1.0 -dir $ip_path
set open_core [ipx::find_open_core user.org:user:$ip_name:1.0]

if {$int_type == "slave" || $int_type == "master_slave"} {
    add_peripheral_interface $interface_name_slave \
	-interface_mode slave \
	-axi_type $axi_type \
	$open_core
}
if {$int_type == "master" || $int_type == "master_slave"} {
    add_peripheral_interface $interface_name_master \
	-interface_mode master \
	-axi_type $axi_type \
	$open_core
}
generate_peripheral $open_core
write_peripheral $open_core

# IP edit project
ipx::edit_ip_in_project -upgrade true -name edit_$ip_name -directory $ip_path $ip_path/[set ip_name]_1.0/component.xml

# Add hdl sources
remove_files {*}[glob $ip_path/[set ip_name]_1.0/hdl/*.v]
file delete {*}[glob $ip_path/[set ip_name]_1.0/hdl/*.v]
add_files [glob hdl/*.v] -copy_to $ip_path/[set ip_name]_1.0/hdl
add_files [glob -nocomplain hdl/*.vh] -quiet -copy_to $ip_path/[set ip_name]_1.0/hdl
set_property top $ip_name [current_fileset]

# Add testbench sources
# TODO

update_compile_order -fileset [current_fileset]
ipx::merge_project_changes files [ipx::current_core]
ipx::merge_project_changes hdl_parameters [ipx::current_core]

# Check for syntax errors
# If we don't do this here, it will generate subtle errors when running simulation
synth_design -rtl

set_property core_revision 1 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

close_project -delete

# Close initial project
close_project -delete

exit


