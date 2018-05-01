`timescale 1ns/1ns
`define PERIOD 5

module sha_top_tb();

   // Module instantiation
   reg clk;
   reg reset;
   reg en;
   reg [95:0] input_M;
   reg [255:0] prev_blk;
   reg [255:0] prev_H;

   wire [255:0] winner_H;
   wire [31:0] nonce;
   wire done;
   wire found;

   sha_top DUT (
		.clk(clk),
		.reset(reset),
		.en(en),

		.prev_blk(prev_blk),
		.prev_H(prev_H),
		.input_M(input_M),

		.nonce(nonce),
		.winner_H(winner_H),
		.done(done),
		.found(found)
		);

	// Test functions
`include "test_fc.sv"

   // Auxiliary counters
   integer i;

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

      // reset inputs to chip
      //chipin1 = 0;
      //chipin2 = 16’ha5;

      // reset simulation parameters
      //resetsim();

      // reset for chip
      //reset_fpga();

      //
      // Add testcases here
      //
`include "test1.sv"

      $display("\nSimulation completed with %d errors\n", errors);
      $stop;
   end

endmodule
