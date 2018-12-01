set DEBUG 1

proc !# {args} {
    global DEBUG
    if {$DEBUG == 1 || $DEBUG == TRUE || $DEBUG == true || $DEBUG == yes || $DEBUG == on || $DEBUG == ON} {
	puts $args
    }
}

proc deval {args} {
    global DEBUG
    if {$DEBUG == 1 || $DEBUG == TRUE || $DEBUG == true || $DEBUG == yes || $DEBUG == on || $DEBUG == ON} {
	eval $args
    }
}
