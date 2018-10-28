#!/bin/bash

vivado -mode tcl -source "$SCRIPTS_TOP"/IP/create_ip.tcl -nolog -nojour
