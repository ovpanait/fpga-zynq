/*
 * Reference:
 * https://www.xilinx.com/support/documentation/ip_documentation/axi4stream_vip/v1_1/pg277-axi4stream-vip.pdf
 * 
 * Add verification IP to a project -> right click -> Open IP Example Design
 */

import axi4stream_vip_pkg::*;
import design_1_axi4stream_vip_0_0_pkg::*;
import design_1_axi4stream_vip_1_0_pkg::*;

`include "test_fc.vh"

module tb_main(
	       );

   // Error count to check how many comparison failed
   xil_axi4stream_uint                            error_cnt = 0; 
   // Comparison count to check how many comparsion happened
   xil_axi4stream_uint                            comparison_cnt = 0;

   // Monitor transaction from master VIP
   axi4stream_monitor_transaction                 mst_monitor_transaction;
   // Monitor transaction queue for master VIP 
   axi4stream_monitor_transaction                 master_moniter_transaction_queue[$];
   // Size of master_moniter_transaction_queue
   xil_axi4stream_uint                           master_moniter_transaction_queue_size =0;
   // Scoreboard transaction from master monitor transaction queue
   axi4stream_monitor_transaction                 mst_scb_transaction;
   // Monitor transaction for slave VIP
   axi4stream_monitor_transaction                 slv_monitor_transaction;
   // Monitor transaction queue for slave VIP
   axi4stream_monitor_transaction                 slave_moniter_transaction_queue[$];
   // Size of slave_moniter_transaction_queue
   xil_axi4stream_uint                            slave_moniter_transaction_queue_size =0;
   // Scoreboard transaction from slave monitor transaction queue
   axi4stream_monitor_transaction                 slv_scb_transaction;

   // Master VIP agent verbosity level
   xil_axi4stream_uint                           mst_agent_verbosity = 0;
   // Slave VIP agent verbosity level
   xil_axi4stream_uint                           slv_agent_verbosity = 0;

   design_1_axi4stream_vip_0_0_mst_t                              mst_agent;
   design_1_axi4stream_vip_1_0_slv_t                              slv_agent;

   // Clock signal
   bit                                     clock;
   // Reset signal
   bit                                     reset;

   // Test signals
   reg [7:0] 				   data_out[];
   
   reg [31:0] 				   blk_version;
   reg [255:0] 				   prev_blk_header_hash;
   reg [255:0] 				   merkle_root_hash;
   reg [31:0] 				   blk_time;
   reg [31:0] 				   blk_nbits;
   reg [31:0] 				   blk_nonce;

   wire [255:0] 			   bitcoin_blk;
   // instantiate bd
   design_1_wrapper DUT(
			.aresetn(reset),
			.aclk(clock)
			);

   always #10 clock <= ~clock;

   initial
     begin
	reset <= 0;
	@(posedge clock);
	@(negedge clock) reset <= 1;    
     end

   //Main process
   initial begin
      mst_monitor_transaction = new("master monitor transaction");
      slv_monitor_transaction = new("slave monitor transaction");

      mst_agent = new("master vip agent",DUT.design_1_i.axi4stream_vip_0.inst.IF);
      slv_agent = new("slave vip agent",DUT.design_1_i.axi4stream_vip_1.inst.IF);
      $timeformat (-12, 1, " ps", 1);
      
      mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
      slv_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
      
      mst_agent.set_agent_tag("Master VIP");
      slv_agent.set_agent_tag("Slave VIP");
      // set print out verbosity level.
      mst_agent.set_verbosity(mst_agent_verbosity);
      slv_agent.set_verbosity(slv_agent_verbosity);
      
      mst_agent.start_master();
      slv_agent.start_slave();
      
      // Test 1
      blk_version = 32'h02000000;
      prev_blk_header_hash = 256'h671D0E2FF45DD1E927A51219D1CA1065C93B0C4E8840290A0000000000000000;
      merkle_root_hash = 256'h2CD900FC3513260DF5BD2EABFD456CD2B3D2BACE30CC078215A907C045F4992E;
      blk_time = 32'h74749054;
      blk_nbits = 32'h747B1B18;
      blk_nonce = 32'h43F740C0;
      
      fork
	 begin
            $display("Sending ...");

	    tester #($size(blk_version))::packed_to_unpacked(blk_version, data_out);
	    tester::print_unpacked(data_out);
	    gen_transaction(data_out);
	    
	    tester #($size(prev_blk_header_hash))::packed_to_unpacked(prev_blk_header_hash, data_out);
	    tester::print_unpacked(data_out);
	    gen_transaction(data_out);

	    tester #($size(merkle_root_hash))::packed_to_unpacked(merkle_root_hash, data_out);
	    tester::print_unpacked(data_out);
	    gen_transaction(data_out);

	    tester #($size(blk_time))::packed_to_unpacked(blk_time, data_out);
	    tester::print_unpacked(data_out);
	    gen_transaction(data_out);

	    tester #($size(blk_nbits))::packed_to_unpacked(blk_nbits, data_out);
	    tester::print_unpacked(data_out);
	    gen_transaction(data_out);

	    tester #($size(blk_nonce))::packed_to_unpacked(blk_nonce, data_out);
	    tester::print_unpacked(data_out);
	    gen_transaction(data_out);

            $display("Sent all the data...");
	 end
	 begin
            slv_gen_tready();
	 end
      join
      
      wait(comparison_cnt == 8);
      
      if(error_cnt == 0) begin
	 $display("EXAMPLE TEST DONE : Test Completed Successfully");
      end else begin  
	 $display("EXAMPLE TEST DONE ",$sformatf("Test Failed: %d Comparison Failed", error_cnt));
      end 
      $finish;

   end

   task slv_gen_tready();
      axi4stream_ready_gen                           ready_gen;
      ready_gen = slv_agent.driver.create_ready("ready_gen");
      ready_gen.set_ready_policy(XIL_AXI4STREAM_READY_GEN_OSC);
      ready_gen.set_low_time(2);
      ready_gen.set_high_time(6);
      slv_agent.driver.send_tready(ready_gen);
   endtask :slv_gen_tready

   initial begin
      forever begin
	 mst_agent.monitor.item_collected_port.get(mst_monitor_transaction);
	 master_moniter_transaction_queue.push_back(mst_monitor_transaction);
	 master_moniter_transaction_queue_size++;
      end  
   end 

   initial begin
      forever begin
	 slv_agent.monitor.item_collected_port.get(slv_monitor_transaction);
	 slave_moniter_transaction_queue.push_back(slv_monitor_transaction);
	 slave_moniter_transaction_queue_size++;
      end
   end

   initial begin
      forever begin
	 wait (master_moniter_transaction_queue_size>0 ) begin
            xil_axi4stream_data_byte mst_data [0:3];
            mst_scb_transaction = master_moniter_transaction_queue.pop_front;
            master_moniter_transaction_queue_size--;
            
            mst_scb_transaction.get_data(mst_data);
	    print_data("Received master data: ", mst_data);
	 end
      end
   end // initial begin

   initial begin
      forever begin
	 wait (slave_moniter_transaction_queue_size > 0) begin
	    xil_axi4stream_data_byte slv_data [3:0];
	    slv_scb_transaction = slave_moniter_transaction_queue.pop_front;
	    slave_moniter_transaction_queue_size--;  
	    
	    slv_scb_transaction.get_data(slv_data);
	    print_data("Received slave data: ", slv_data);
	    
	    comparison_cnt++;
         end  
      end
   end // initial begin

   /* ******************** */
`define  miner  DUT.design_1_i.test_ip_0.inst.test_miner.miner

   always @(posedge `miner.start or negedge `miner.start) begin
      $display("`miner.start changed: %H", `miner.start);
      print_miner();
   end
   
   always @(posedge `miner.bitcoin_done or negedge `miner.bitcoin_done) begin
      $display("`miner.bitcoin_done changed: %H", `miner.bitcoin_done);
      print_miner();
   end


   task automatic gen_rand_transaction(ref axi4stream_transaction wr_transaction);
      wr_transaction = mst_agent.driver.create_transaction("Master VIP write transaction");
      wr_transaction.set_xfer_alignment(XIL_AXI4STREAM_XFER_RANDOM);
      WR_TRANSACTION_FAIL: assert(wr_transaction.randomize());
   endtask

   // Tasks
   task gen_transaction(input [7:0] data[]);
      for (int i = 0; i < $size(data); i = i + 4)
	begin
	   xil_axi4stream_data_byte data_dbg[4];
	   axi4stream_transaction                         wr_transaction; 

	   gen_rand_transaction(wr_transaction);
	   wr_transaction.set_data('{data[i+3], data[i+2], data[i+1], data[i]});

	   wr_transaction.get_data(data_dbg);
	   print_data("Debug: ", data_dbg);

	   mst_agent.driver.send(wr_transaction);
	end
   endtask; // gen_transaction
   
   
   // Functions
   function print_miner();
      begin
	 $display("");
	 $display("Time: %t", $time);
	 $display("miner.blk_version: 0x%H", `miner.blk_version);
	 $display("miner.prev_blk_header_hash: 0x%H", `miner.prev_blk_header_hash);
	 $display("miner.merkle_root_hash: 0x%H", `miner.merkle_root_hash);
	 $display("miner.blk_time: 0x%H", `miner.blk_time);
	 $display("miner.blk_nbits: 0x%H", `miner.blk_nbits);
	 $display("miner.blk_nonce: 0x%H", `miner.blk_nonce);

	 $display("miner.bitcoin_blk: 0x%H", `miner.bitcoin_blk);
	 $display("miner.bitcoin_nonce: 0x%H", `miner.bitcoin_nonce);
	 $display("miner.bitcoin_done: 0x%H", `miner.bitcoin_done);
	 $display("");
      end
   endfunction

   function print_data(string msg, xil_axi4stream_data_byte data[4]);
      begin
	 $write({msg, " "});

	 // data is stored in litle endian
	 $write("0x");
	 for(int i = $size(data) - 1; i >= 0; i--) begin
	    $write("%H", data[i]);
	 end
	 $display("");
      end
   endfunction // print_data
endmodule

