#!/bin/bash

VIVADO_SDK="$HOME/Xilinx/Tools/Vivado/2018.2/settings64.sh"

source "${VIVADO_SDK}"
export SIM_PATH="$(pwd)"
export PATH="$PATH:$SIM_PATH"
