set outputDir ./outputs
file mkdir $outputDir

read_verilog  [ glob ./Sources/*.v ]
read_verilog [ glob ./Tb/*.sv ]
read_xdc [ glob ./Constraints/*.xdc ]

set_property top tb_main [current_fileset -simset]
#set_property include_dirs ./include [current_fileset -simset]

export_simulation -force -simulator xsim -directory "$outputDir/export_sim" -include "$env(SIM_PATH)/include"
exit