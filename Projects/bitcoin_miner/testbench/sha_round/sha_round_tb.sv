`timescale 1ns/1ns
`define PERIOD 5

module sha_round_tb();

   // Module instantiation
   reg clk;
   reg reset;
   reg en;
   reg [31:0] a_i, b_i, c_i, d_i, e_i, f_i, g_i, h_i;
   reg [1023:0] K, W;
   wire [31:0] a_o, b_o, c_o, d_o, e_o, f_o, g_o, h_o;
   wire en_o;

   sha_round DUT (
		.clk(clk),
		.reset(reset),
		.en(en),
		.a(a_i),
		.b(b_i),
		.c(c_i),
		.d(d_i),
		.e(e_i),
		.f(f_i),
		.g(g_i),
		.h(h_i),
		.a_next(a_o),
		.b_next(b_o),
		.c_next(c_o),
		.d_next(d_o),
		.e_next(e_o),
		.f_next(f_o),
		.g_next(g_o),
		.h_next(h_o),
		.K(K),
		.W(W),
		.en_next(en_o)
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
