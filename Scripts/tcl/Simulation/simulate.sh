#!/bin/bash
set -e

usage() {
    cat <<EOF
WARNING: Command line arguments are executed sequentially.
Usage: 
Export simulation:
$SCRIPT [--top <top_module_name] --export-sim

Simulate:
$SCRIPT --sim

Synthesize design:
$SCRIPT --top <top_module_name> --synth

Implement design:
$SCRIPT --top <top_module_name> --implement

Create project and open vivado tcl shell:
$SCRIPT --console_proj
EOF

    exit 1;
}

SCRIPT="$(basename "$0")"

LOGGING="-nolog -nojournal"
top=""

while [ "$1" != "" ];do
    opt="$1"
    case $opt in
	"--help")
	    usage;
	    ;;
	"--top")
	    shift
	    top="$1"
	    [ "$1" == "" ] && usage
	    ;;
	"--console-proj")
	    vivado -mode tcl -source "$SIM_TOP"/create_proj.tcl ${LOGGING};
	    exit 0
	    ;;
	"--export_sim")
	    vivado -mode tcl -source "$SIM_TOP"/export_sim.tcl ${LOGGING}
	    ;;
	"--sim")
	    pushd ./outputs/export_sim/xsim > /dev/null
	    ./tb_main.sh -reset_run && ./tb_main.sh
	    popd
	    ;;
	"--synth")
	    [ "$top" == "" ] && { echo "ERROR: Top module option missing.";
				  usage; }
	    vivado -mode tcl -source "$SIM_TOP"/synth.tcl ${LOGGING} \
		   -tclargs "$top"
	    ;;
	"--implement")
	    [ "$top" == "" ] && { echo "ERROR: Top module option missing.";
				  usage; }
	    vivado -mode tcl -source "$SIM_TOP"/implement.tcl ${LOGGING} \
		   -tclargs "$top"
	    ;;
    esac
    shift
done
