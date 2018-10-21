
# Add ip
set_property  ip_repo_paths  /home/ovidiu/Xilinx/xilinx-projects-temp/test1/ip_repo/test_ip/test_ip_1.0 [current_project]
update_ip_catalog

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

create_bd_cell -type ip -vlnv user.org:user:test_ip:1.0 test_ip_0

# Create connections
connect_bd_intf_net [get_bd_intf_pins axi4stream_vip_0/M_AXIS] [get_bd_intf_pins test_ip_0/S00_AXIS]
connect_bd_intf_net [get_bd_intf_pins test_ip_0/M00_AXIS] [get_bd_intf_pins axi4stream_vip_1/S_AXIS]

startgroup
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "New Clocking Wizard (100 MHz)" }  [get_bd_pins axi4stream_vip_0/aclk]

apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "New Clocking Wizard (100 MHz)" }  [get_bd_pins axi4stream_vip_1/aclk]
endgroup

startgroup
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto} rst_polarity {ACTIVE_HIGH}}  [get_bd_pins clk_wiz/reset]

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sys_clock ( System Clock ) } Manual_Source {Auto}}  [get_bd_pins clk_wiz/clk_in1]

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto} rst_polarity {ACTIVE_LOW}}  [get_bd_pins rst_clk_wiz_100M/ext_reset_in]

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto} rst_polarity {ACTIVE_HIGH}}  [get_bd_pins clk_wiz_1/reset]

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sys_clock ( System Clock ) } Manual_Source {Auto}}  [get_bd_pins clk_wiz_1/clk_in1]

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto} rst_polarity {ACTIVE_LOW}}  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
endgroup

validate_bd_design -force

# Create verilog wrapper
make_wrapper -files [get_files /home/ovidiu/Xilinx/xilinx-projects-temp/test3/project_1/project_1.srcs/sources_1/bd/design_1/design_1.bd] -top

add_files -norecurse /home/ovidiu/Xilinx/xilinx-projects-temp/test3/project_1/project_1.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v

# SImulation
set_property SOURCE_SET sources_1 [get_filesets sim_1]
import_files -fileset sim_1 -norecurse /home/ovidiu/Xilinx/xilinx-projects-temp/test3/Tb/master-slave_axis_test.sv

update_compile_order -fileset sim_1
set_property top tb_main [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
