read_verilog  [ glob ./Sources/*.v ]
read_verilog [ glob ./Tb/*.sv ]
read_xdc [ glob -nocomplain ./Constraints/*.xdc ] -quiet

set_property top tb_main [current_fileset -simset]

set outputDir ./outputs
file mkdir $outputDir

export_simulation \
    -force \
    -simulator xsim \
    -directory "$outputDir/export_sim" \
    -include "$env(SIM_PATH)/include"

exit
