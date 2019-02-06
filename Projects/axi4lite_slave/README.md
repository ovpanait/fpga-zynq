AXI4-lite slave minimal working example
---------------------------------------

Toggle ARTY-Z7 RGB led(LD4) color by writing to memory-mapped AXI registers.

This example consists of 2 memory-mapped 32-bit AXI registers accessible from Linux using devmem:
- 1 R/W control register (physical address 0x43C00000) - 
- 1 Read-only status register (physical address 0x43C00004)

1. Create IP repository
```sh
$ make
```

2. Add IP repository -> create block design -> Check address editor
TODO

3. Generate bitstream and load on target

4. Toggle RGB color from Linux devmem
```sh
# Write to control register (0x43C00000) to change colors

# Toggle blue
root@xilinx-zynq:~# devmem2 0x43C00000 w 0x16161616

# Toggle red
root@xilinx-zynq:~# devmem2 0x43C00000 w 0xF3F3F3F3

# Toggle green
root@xilinx-zynq:~# devmem2 0x43C00000 w 0xA1A1A1A1

# Turn LED off
root@xilinx-zynq:~# devmem2 0x43C00000 w 0x0

# Read status register (0x43C00004)
# 0x0F0F0F0F - LED on
# 0x32323232 - LED off

root@xilinx-zynq:~# devmem2 0x43C00004
/dev/mem opened.
Memory mapped at address 0xb6fcc000.
Read at address  0x43C00004 (0xb6fcc004): 0x32323232
```sh