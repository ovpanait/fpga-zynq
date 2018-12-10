#!/bin/bash

while [ "$1" != "" ];do
    opt="$1"
    case $opt in
	"--help")
	;;
	"--top")
	    shift
	    top="$1"
	    ;;
	*)
	    echo "$opt : Unrecognized option. Exiting..."
	    exit 1;
	    ;;
    esac
    shift
done

vivado -mode tcl -source "$SCRIPTS_TOP"/IP/create_ip.tcl -nolog -nojour -tclargs $top
