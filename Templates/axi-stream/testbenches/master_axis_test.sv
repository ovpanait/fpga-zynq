/*
 * Reference:
 * https://www.xilinx.com/support/documentation/ip_documentation/axi4stream_vip/v1_1/pg277-axi4stream-vip.pdf
 * 
 * Add verification IP to a project -> right click -> Open IP Example Design
 */

`timescale 1ns / 1ps

import axi4stream_vip_pkg::*;
import ex_sim_axi4stream_vip_mst_0_pkg::*;

module axi4stream_vip_0_exdes_tb(
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

  ex_sim_axi4stream_vip_mst_0_mst_t                              mst_agent;
  
  // Clock signal
  bit                                     clock;
  // Reset signal
  bit                                     reset;

  // instantiate bd
  chip DUT(
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

    mst_agent = new("master vip agent",DUT.ex_design.axi4stream_vip_mst.inst.IF);
    $timeformat (-12, 1, " ps", 1);
    
    mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
    
    mst_agent.set_agent_tag("Master VIP");
    // set print out verbosity level.
    mst_agent.set_verbosity(mst_agent_verbosity);
    
    mst_agent.start_master();
        
    fork
      begin
        //mst_gen_transaction();
        //$display("Simple master to slave transfer example with randomization completes");
        for(int i = 0; i < 30;i++) begin
          mst_gen_transaction();
        end  
        $display("Looped master to slave transfers example with randomization completes");
      end
    join
    

    wait(comparison_cnt == 30);

    $finish;

  end

  task mst_gen_transaction();
    axi4stream_transaction                         wr_transaction; 
    wr_transaction = mst_agent.driver.create_transaction("Master VIP write transaction");
    wr_transaction.set_xfer_alignment(XIL_AXI4STREAM_XFER_RANDOM);
    WR_TRANSACTION_FAIL: assert(wr_transaction.randomize());
    mst_agent.driver.send(wr_transaction);
  endtask

  initial begin
    forever begin
      mst_agent.monitor.item_collected_port.get(mst_monitor_transaction);
      master_moniter_transaction_queue.push_back(mst_monitor_transaction);
      master_moniter_transaction_queue_size++;
    end  
  end 

  initial begin
   forever begin
      wait (master_moniter_transaction_queue_size>0 ) begin
        mst_scb_transaction = master_moniter_transaction_queue.pop_front;
        master_moniter_transaction_queue_size--;
          comparison_cnt++;
        end  
      end 
   end
endmodule