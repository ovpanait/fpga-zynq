#!/bin/bash

# Generate dts for Xilinx Zynq

set -e

# Hardcoded
VIV_SDK="/home/ovidiu/Xilinx/Tools/SDK/2018.2/settings64.sh"
XIL_SDK="/home/ovidiu/Xilinx/ArtyZ7/device-tree-xlnx"

if [ "$#" -ne 1 ];then
	echo "Usage: cdts.sh <path-to-hdf>"
	exit 1
fi

HDF_FILE="$1"

# Source Vivado SDK
. "${VIV_SDK}"

# Generate dts
hsi <<EOF
open_hw_design "${HDF_FILE}"
set_repo_path "${XIL_SDK}"
create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
generate_target -dir my_dts
EOF

dtc -I dts -O dtb -o zynq-artyz7.dtb ./my_dts/system-top.dts
