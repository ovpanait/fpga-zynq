#!/bin/bash

if [ "${#}" -ne 1 ]; then
    echo "Usage: bitbin.sh <file.bit>"
    exit 1
fi

cat > tmp.bif <<EOF
all:
{
"${1}"
}
EOF

bootgen -image tmp.bif -w -process_bitstream bin
rm tmp.bif
