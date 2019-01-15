#!/bin/bash
set -e

SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(dirname $0)"

LOGGING="-nolog -nojournal"
OUT_DIR="outputs"

usage() {
    cat <<EOF
TODO
EOF
    exit 1;
}

check_out_dir() {
  if [ -d "${OUT_DIR}" ]; then
    echo "Directory ${OUT_DIR} exists. Overwrite? [Y/n]"
    read ans
    case ans in
      "n|N|no|NO")
        echo "Exiting..."
        exit 1
        ;;
    esac
  fi

    rm -rf "${OUT_DIR}"
    mkdir "${OUT_DIR}"
}

while [ "$1" != "" ];do
    OPT="$1"
    case $OPT in
	"--help")
	    HELP="1"
	    ;;
	"--top")
	    shift
	    TOP="$1"
	    ;;
	"--console-proj")
	    CONSOLE="1"
	    ;;
	"--export_sim")
	    EXPORT_SIM="1"
	    ;;
	"--sim")
	    SIM="1"
	    ;;
	"--synth")
	    SYNTH="1"
	    ;;
	"--implement")
	    IMPLEMENT="1"
	    ;;
	*)
	    echo "${OPT} invalid argument. Exiting..."
	    exit 1
	    ;;
    esac
    shift
done

if [ "${HELP}" == "1" ];then
    usage;
    exit 1
fi

if [ "${CONSOLE}" == "1" ];then
    vivado -mode tcl -source "${SCRIPT_DIR}"/create_proj.tcl ${LOGGING};
    exit 0
fi

if [ "${EXPORT_SIM}" == "1" ];then
    check_out_dir;
    vivado -mode tcl -source "${SCRIPT_DIR}"/export_sim.tcl ${LOGGING}
fi

if [ "${SIM}" == "1" ];then
    pushd ./outputs/export_sim/xsim > /dev/null
    ./tb_main.sh -reset_run && ./tb_main.sh
    popd
fi

if [ "${SYNTH}" != "1" -a "${IMPLEMENT}" != "1" ]; then
   exit 0
fi

if [ -z "${TOP}" ]; then
    echo "ERROR: --top <top_module> missing"
    usage;
    exit 1
fi

if [ "${SYNTH}" == "1" ];then
    check_out_dir
    vivado -mode tcl -source "${SCRIPT_DIR}"/synth.tcl ${LOGGING} \
	   -tclargs "${TOP}"
fi

if [ "${IMPLEMENT}" == "1" ]; then
    check_out_dir
    vivado -mode tcl -source "${SCRIPT_DIR}"/implement.tcl ${LOGGING} \
	   -tclargs "${TOP}"
fi
