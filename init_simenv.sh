#!/bin/bash

export VIVADO_SDK="${VIVADO_SDK:-$HOME/Xilinx/Tools/Vivado/2018.2/settings64.sh}"
source "${VIVADO_SDK}"

export SCRIPTS_TOP="$(pwd)/Scripts/tcl"
export INCLUDE_DIR="$(pwd)/Examples/include"

export PATH="$PATH:$(ls -1d $SCRIPTS_TOP/*/ | tr "\n" ":")"
