source $env(SIM_TOP)/create_proj.tcl

set_property top tb_main [current_fileset -simset]

set outputDir ./outputs
file mkdir $outputDir

export_simulation \
    -force \
    -simulator xsim \
    -directory "$outputDir/export_sim" \
    -include "$env(INCLUDE_DIR)"

exit
