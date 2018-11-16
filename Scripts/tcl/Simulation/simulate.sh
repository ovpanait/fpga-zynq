#!/bin/bash
set -e

while [ "$1" != "" ];do
    opt="$1"
    case $opt in
	"export_sim")
	    vivado -mode tcl -source "$SIM_TOP"/export_sim.tcl -nolog -nojournal
	    ;;
	"check_impl")
	    shift
	    vivado -mode tcl -source "$SIM_TOP"/check_impl.tcl -nolog -nojournal \
		   -tclargs "$1"
	    exit 0
	    ;;
    esac
    shift
done

cd ./outputs/export_sim/xsim
./tb_main.sh -reset_run && ./tb_main.sh

