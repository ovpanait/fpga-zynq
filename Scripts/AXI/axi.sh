#!/bin/bash

IP_REPO_DIR="ip_repo"
PROJ_DIR="test_proj"
SIM_DIR="outputs"

SCRIPT_DIR="$(dirname $0)"
SCRIPT_NAME="$(basename $0)"

usage() {
    cat <<EOF

Usage:
${SCRIPT_NAME} --top <top_module> [--help] [--force] [--create-axis-sim-proj]

Create AXI-Stream IP from the current directory hierarchy.

Options:
--top			Specify Verilog top module
--create-axis-sim-proj	Create generic AXI STREAM simulation project
--force			Overwrite "${IP_REPO_DIR}" directory
EOF
    exit 1;
}

while [ "$1" != "" ];do
    OPT="$1"
    case ${OPT} in
	"--help")
	    HELP="1"
	;;
	"--top")
	    shift
	    TOP="$1"
	    ;;
	"--force")
	    FORCE="1"
	    ;;
	"--create-axis-sim-proj")
	    AXIS_PROJ="1"
	    ;;
	*)
	    echo "${OPT} : Unrecognized option. Exiting..."
	    usage
	    exit 1
	    ;;
    esac
    shift
done

if [ "${HELP}" == "1" ]; then
    usage;
    exit 1
fi

if [ -z "${TOP}" ]; then
    echo "ERROR: --top <top_module> missing"
    usage;
    exit 1
fi

if [ "${FORCE}" != "1" ]; then
    if [ -e "${IP_REPO_DIR}" ]; then
	echo "ERROR: ${IP_REPO_DIR} directory exists. Run script with --force to override.";
	exit 1
    fi

    if [ -e "${PROJ_DIR}" ] && [ "${AXIS_PROJ}" == "1" ]; then
	echo "ERROR: ${PROJ_DIR} directory exists. Run script with --force to override.";
	exit 1
    fi
fi

rm -rf "${IP_REPO_DIR}"

# Create AXI-Stream IP
vivado -mode tcl -source "${SCRIPT_DIR}"/create_ip.tcl -nolog -nojour -tclargs "${TOP}"

#
# Create generic AXI-Stream simulation project
#
# This will take the IP generated previously and put it in a master/slave configuration
# that uses Vivado AXI-Stream Verification IPs.
#
if [ "${AXIS_PROJ}" == "1" ]; then
    rm -rf "${SIM_DIR}"
    rm -rf "${PROJ_DIR}"
    vivado -mode tcl -source "${SCRIPT_DIR}"/create_axi_stream_sim_proj.tcl -nolog -nojour -tclargs "${TOP}"
fi
