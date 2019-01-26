#!/bin/bash

# Generate dts for Xilinx Zynq

set -e

if [ "$#" -ne 1 ];then
	echo "Usage: cdts.sh <path-to-hdf>"
	exit 1
fi

HDF_FILE="$1"

# Generate dts
hsi <<EOF
open_hw_design "${HDF_FILE}"
set_repo_path "${DTX_SDK}"
create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
generate_target -dir my_dts
EOF

dtc -I dts -O dtb -o zynq-artyz7.dtb ./my_dts/system-top.dts
