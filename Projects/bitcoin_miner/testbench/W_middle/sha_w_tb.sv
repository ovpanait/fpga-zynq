`timescale 1ns/1ns
`define PERIOD 5

module sha_w_tb();

   // Module instantiation
   reg clk;
   reg reset;
   reg en;
   reg [1023:0] Win;
   wire [1023:0] W;
   wire en_out;

   W_middle DUT (
		.clk(clk),
		.reset(reset),
		.en(en),
		.Win(Win),
		.W(W),
		.en_next(en_out)
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
