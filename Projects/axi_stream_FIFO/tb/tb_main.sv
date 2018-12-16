import axi4stream_vip_pkg::*;
import design_1_axi4stream_vip_0_0_pkg::*;
import design_1_axi4stream_vip_1_0_pkg::*;

`include "test_fc.vh"

module tb_main(
	       );

   xil_axi4stream_uint                            comparison_cnt = 0;

   axi4stream_monitor_transaction                 mst_monitor_transaction;
   axi4stream_monitor_transaction                 master_moniter_transaction_queue[$];
   xil_axi4stream_uint                           master_moniter_transaction_queue_size =0;
   axi4stream_monitor_transaction                 mst_scb_transaction;
   axi4stream_monitor_transaction                 slv_monitor_transaction;
   axi4stream_monitor_transaction                 slave_moniter_transaction_queue[$];
   xil_axi4stream_uint                            slave_moniter_transaction_queue_size =0;
   axi4stream_monitor_transaction                 slv_scb_transaction;

   xil_axi4stream_uint                           mst_agent_verbosity = 0;
   xil_axi4stream_uint                           slv_agent_verbosity = 0;

   design_1_axi4stream_vip_0_0_mst_t                              mst_agent;
   design_1_axi4stream_vip_1_0_slv_t                              slv_agent;

   bit                                     clock;
   bit                                     reset;

   reg [7:0] 				   data_out[];
   
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

      mst_agent.set_verbosity(mst_agent_verbosity);
      slv_agent.set_verbosity(slv_agent_verbosity);
      
      mst_agent.start_master();
      slv_agent.start_slave();
      
      fork
	 begin
	    // FIFO size = 16 x 32-bit words
            $display("Sending 16 transactions...");
	    
	    for (int i = 0; i < 16; i=i+1) begin
	       axi4stream_transaction wr_transaction;
	       gen_rand_transaction(wr_transaction);
	       mst_agent.driver.send(wr_transaction);
	    end
	    
            $display("Sent all the data...");
	 end
	 begin
            slv_gen_tready();
	 end
      join
      
      wait(comparison_cnt == 16);
      
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
	    print_data("Master VIP data: ", mst_data);
	 end
      end
   end

   initial begin
      forever begin
	 wait (slave_moniter_transaction_queue_size > 0) begin
	    xil_axi4stream_data_byte slv_data [3:0];
	    slv_scb_transaction = slave_moniter_transaction_queue.pop_front;
	    slave_moniter_transaction_queue_size--;  
	    
	    slv_scb_transaction.get_data(slv_data);
	    print_data("Slave VIP data: ", slv_data);
	    
	    comparison_cnt++;
         end  
      end
   end

   task automatic gen_rand_transaction(ref axi4stream_transaction wr_transaction);
      wr_transaction = mst_agent.driver.create_transaction("Master VIP write transaction");
      wr_transaction.set_xfer_alignment(XIL_AXI4STREAM_XFER_RANDOM);
      WR_TRANSACTION_FAIL: assert(wr_transaction.randomize());
   endtask

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
   endfunction
endmodule

