source $env(SIM_TOP)/create_proj.tcl

set top_name [lindex $argv 0]

synth_design -top $top_name -part xc7z020clg400-1 -flatten rebuilt
