set outputDir ./outputs
file mkdir $outputDir

read_verilog  [ glob ./Sources/*.v ]
read_verilog [ glob -nocomplain ./Sources/*.sv ] -quiet

#read_verilog [ glob ./Tb/*.sv ]
add_files -fileset [get_filesets sim_1] -norecurse [ glob ./Tb/*.sv ]

read_xdc [ glob -nocomplain ./Constraints/*.xdc ] -quiet
