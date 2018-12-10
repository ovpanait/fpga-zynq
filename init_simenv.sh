#!/bin/bash

export VIVADO_SDK="${VIVADO_SDK:-$HOME/Xilinx/Tools/Vivado/2018.2/settings64.sh}"
source "${VIVADO_SDK}"

export SCRIPTS_TOP="$(pwd)/Scripts"
export SIM_TOP="$SCRIPTS_TOP/Simulation"
export INCLUDE_DIR="$(pwd)/Templates/include"

export TCL_INCLUDE="${SCRIPTS_TOP}/include"

export PATH="$PATH:$(find $SCRIPTS_TOP -type d | tr "\n" ":")"
