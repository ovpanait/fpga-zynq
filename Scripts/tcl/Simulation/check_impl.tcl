source $env(SIM_TOP)/create_proj.tcl

set top_name [lindex $argv 0]

# Uncomment for verbose logging
synth_design -top $top_name -part xc7z020clg400-1 -flatten rebuilt 

opt_design
place_design
phys_opt_design
#write_checkpoint -force $outputDir/post_place
#report_timing_summary -file $outputDir/post_place_timing_summary.rpt

route_design
#write_checkpoint -force $outputDir/post_route
#report_timing_summary -file $outputDir/post_route_timing_summary.rpt
#report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/post_route_timing.rpt
#report_clock_utilization -file $outputDir/clock_util.rpt
#report_utilization -file $outputDir/post_route_util.rpt
#report_power -file $outputDir/post_route_power.rpt
#report_drc -file $outputDir/post_imp_drc.rpt
#write_verilog -force $outputDir/cpu_impl_netlist.v
#write_xdc -no_fixed_only -force $outputDir/cpu_impl.xdc
