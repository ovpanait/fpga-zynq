AXI-stream FIFO (16 x 32-bit FIFO)
----------------------------------

Simulation (tested with Vivado 2018.2):

```sh
$ git clone https://github.com/ovpanait/fpga-zynq.git
$ cd fpga-zynq
# adjust this per your Vivado sdk directory
$ export VIVADO_SDK="$HOME/Xilinx/Tools/Vivado/2018.2/settings64.sh"
$ . init_simenv.sh
$ cd Projects/axi_stream_FIFO
$ axi.sh --top axis_fifo --create-axis-sim-proj --force
$ simulate.sh --sim
...
Sending 16 transactions...
Master VIP data:  0xa75e9220
Master VIP data:  0xd3c93d57
Master VIP data:  0xdf4f5f65
Master VIP data:  0x7df0aaba
Master VIP data:  0x48309e04
Master VIP data:  0xdfa5d34e
Master VIP data:  0xfd6b09d5
Master VIP data:  0x3e71863f
Master VIP data:  0xf18f7630
Master VIP data:  0x3f90885b
Master VIP data:  0xd0728bb2
Master VIP data:  0x93af52f7
Master VIP data:  0xc55ac136
Master VIP data:  0xd93a0034
Master VIP data:  0x0e189418
Master VIP data:  0x02ed3c88

Slave VIP data:  0xa75e9220
Slave VIP data:  0xd3c93d57
Slave VIP data:  0xdf4f5f65
Slave VIP data:  0x7df0aaba
Slave VIP data:  0x48309e04
Slave VIP data:  0xdfa5d34e
Slave VIP data:  0xfd6b09d5
Slave VIP data:  0x3e71863f
Slave VIP data:  0xf18f7630
Slave VIP data:  0x3f90885b
Slave VIP data:  0xd0728bb2
Slave VIP data:  0x93af52f7
Slave VIP data:  0xc55ac136
Slave VIP data:  0xd93a0034
Slave VIP data:  0x0e189418
Slave VIP data:  0x02ed3c88

#
#  Data sent by the Master VIP (axi4_stream_vip_0) should match the one received by
#  the Slave VIP (axi4_stream_vip_1)
#
```

Testbench block design(open generated test_proj/test_proj.xpr):
![](https://github.com/ovpanait/fpga-zynq/blob/master/Projects/axi_stream_FIFO/testbench.png)
