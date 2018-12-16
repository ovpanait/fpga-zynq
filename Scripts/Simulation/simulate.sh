#!/bin/bash
set -e

SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(dirname $0)"

LOGGING="-nolog -nojournal"
top=""

usage() {
    cat <<EOF
INFO: Command line arguments are executed sequentially.
Usage: 
Export simulation:
$SCRIPT_NAME [--top <top_module_name] --export_sim

Simulate:
$SCRIPT_NAME --sim

Synthesize design:
$SCRIPT_NAME --top <top_module_name> --synth

Implement design:
$SCRIPT_NAME --top <top_module_name> --implement

Create project and open vivado tcl shell:
$SCRIPT_NAME --console_proj
EOF

    exit 1;
}

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
	    vivado -mode tcl -source "${SCRIPT_DIR}"/create_proj.tcl ${LOGGING};
	    exit 0
	    ;;
	"--export_sim")
	    vivado -mode tcl -source "${SCRIPT_DIR}"/export_sim.tcl ${LOGGING}
	    ;;
	"--sim")
	    pushd ./outputs/export_sim/xsim > /dev/null
	    ./tb_main.sh -reset_run && ./tb_main.sh
	    popd
	    ;;
	"--synth")
	    [ "$top" == "" ] && { echo "ERROR: Top module option missing.";
				  usage; }
	    vivado -mode tcl -source "${SCRIPT_DIR}"/synth.tcl ${LOGGING} \
		   -tclargs "$top"
	    ;;
	"--implement")
	    [ "$top" == "" ] && { echo "ERROR: Top module option missing.";
				  usage; }
	    vivado -mode tcl -source "${SCRIPT_DIR}"/implement.tcl ${LOGGING} \
		   -tclargs "$top"
	    ;;
    esac
    shift
done
