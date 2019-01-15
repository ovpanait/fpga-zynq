source $env(TCL_INCLUDE)/debug.tcl

set outputDir ./outputs

read_verilog  [ glob ./hdl/*.v ]
read_verilog [ glob -nocomplain ./hdl/*.sv ] -quiet

add_files -fileset [get_filesets sim_1] -norecurse [ glob -nocomplain ./tb/*.sv ] -quiet

read_xdc [ glob -nocomplain ./constraints/*.xdc ] -quiet
