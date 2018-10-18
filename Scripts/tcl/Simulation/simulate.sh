#!/bin/bash
set -e


if [ "$1" == "export_sim" ];then
    vivado -mode tcl -source "$SIM_PATH"/export_sim.tcl -nolog -nojournal
fi

cd ./outputs/export_sim/xsim && ./tb_main.sh
