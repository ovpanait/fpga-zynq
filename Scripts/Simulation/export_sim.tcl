source $env(SIM_TOP)/create_proj.tcl

set_property top tb_main [current_fileset -simset]

export_simulation \
    -force \
    -simulator xsim \
    -directory "$outputDir/export_sim" \
    -include [list "[pwd]/hdl/include" "[pwd]/tb/include" "[pwd]/include"] \
    -define [list {SIMULATION=1}]

exit
