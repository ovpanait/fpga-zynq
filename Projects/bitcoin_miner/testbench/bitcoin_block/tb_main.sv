`define PERIOD 5

module tb_main();

`define BLK_VERSION 32'h02000000
`define PREV_BLK_HEADER_HASH 256'h671D0E2FF45DD1E927A51219D1CA1065C93B0C4E8840290A0000000000000000
`define MERKLE_ROOT_HASH 256'h2CD900FC3513260DF5BD2EABFD456CD2B3D2BACE30CC078215A907C045F4992E
`define BLK_TIME 32'h74749054
`define BLK_NBITS 32'h747B1B18
`define BLK_NONCE 32'h43F740C0

`define BITCOIN_BLK 256'hFF277F1F11CD72EFFE537F5E8A2690E08D8C911682D8A8150000000000000000
   
   /* Inputs */
   reg clk;
   reg reset;
   reg start;
   reg [31:0] blk_version;
   reg [255:0] prev_blk_header_hash;
   reg [255:0] merkle_root_hash;
   reg [31:0]  blk_time;
   reg [31:0]  blk_nbits;
   reg [31:0]  blk_nonce;

   /* Outputs */
   wire [255:0] bitcoin_blk;
   wire [31:0] 	bitcoin_nonce;
   wire 	bitcoin_done;
   
   bitcoin_block  DUT (
		       .clk(clk),
		       .reset(reset),
		       .start(start),
		       .blk_version(blk_version),
		       .prev_blk_header_hash(prev_blk_header_hash),
		       .merkle_root_hash(merkle_root_hash),
		       .blk_time(blk_time),
		       .blk_nbits(blk_nbits),
		       .blk_nonce(blk_nonce),

		       .bitcoin_blk(bitcoin_blk),
		       .bitcoin_nonce(bitcoin_nonce),
		       .bitcoin_done(bitcoin_done)
		       );

   // Test functions
`include "test_fc.h"

   initial begin
      clk <= 0;
      forever #(`PERIOD) clk = ~clk;
   end
   
   initial begin
      reset <= 0;
      @(posedge clk); //may need several cycles for reset
      @(negedge clk) reset = 1;
   end
   
   initial begin
      errors = 0; // reset error count

      // Test 1
      $display("Begin testing scenario 1...");
      $display("Testing sha block hash output.. ");

      // Testcase init
      wait(reset)
	@(posedge clk);
      @(negedge clk) reset = 0;

      // Testcase
      @(negedge clk) begin
	 start = 1'b1;
	 blk_version = `BLK_VERSION;
	 prev_blk_header_hash = `PREV_BLK_HEADER_HASH;
	 merkle_root_hash = `MERKLE_ROOT_HASH;
	 blk_time = `BLK_TIME;
	 blk_nbits = `BLK_NBITS;
	 blk_nonce = `BLK_NONCE;
      end
      @(negedge clk) start = 1'b0;

      // Test output for 1st input
      //repeat(128) @(posedge clk);
      @(posedge bitcoin_done);
      @(negedge clk) begin
	 tester #(256)::verify_output(bitcoin_blk, `BITCOIN_BLK);
	 $display("bitcoin block: %h", bitcoin_blk);
      end
      
      $display("\nSimulation completed with %d errors\n", errors);
      $stop;
   end

endmodule
