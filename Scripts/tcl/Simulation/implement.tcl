source $env(SIM_TOP)/synth.tcl

opt_design
place_design
phys_opt_design
deval write_checkpoint -force $outputDir/post_place
deval report_timing_summary -file $outputDir/post_place_timing_summary.rpt

route_design
deval write_checkpoint -force $outputDir/post_route
deval report_timing_summary -file $outputDir/post_route_timing_summary.rpt
deval report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/post_route_timing.rpt
deval report_clock_utilization -file $outputDir/clock_util.rpt
deval report_utilization -file $outputDir/post_route_util.rpt
deval report_power -file $outputDir/post_route_power.rpt
deval report_drc -file $outputDir/post_imp_drc.rpt
deval write_verilog -force $outputDir/cpu_impl_netlist.v
deval write_xdc -no_fixed_only -force $outputDir/cpu_impl.xdc
