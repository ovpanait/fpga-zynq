`timescale 1ns/1ns
`define PERIOD 5

module tb_main();

   // Module instantiation
   reg clk;
   reg reset;
   reg en;
   reg [511:0] M;
   wire [511:0] W;
   wire 	en_out;

   W_start DUT (
		.clk(clk),
		.reset(reset),
		.en(en),
		.M(M),

		.W(W),
		.en_next(en_out)
		);

   // Test functions
`include "test_fc.vh"

   // Auxiliary counters
   integer 	i;

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

      // Inputs
`define T1_M1 512'h02000000671D0E2FF45DD1E927A51219D1CA1065C93B0C4E8840290A00000000000000002CD900FC3513260DF5BD2EABFD456CD2B3D2BACE30CC078215A907C0

      // Expected outputs
`define T1_WRES1 512'h15a907c030cc0782b3d2bacefd456cd2f5bd2eab3513260d2cd900fc00000000000000008840290ac93b0c4ed1ca106527a51219f45dd1e9671d0e2f02000000

      $display("Begin testing scenario 1...");
      $display("Testing W output and number of clock cycles... ");

      // Testcase init
      wait(reset)
	@(posedge clk);
      @(negedge clk) reset = 0;

      // Testcase
      @(negedge clk) begin
	 en = 1'b1;
	 M = `T1_M1;
      end

      @(posedge en_out);
      @(negedge clk) begin
	 tester #($size(W))::verify_output(W, `T1_WRES1);
	 en = 1'b0;
      end

      @(posedge clk);
      @(negedge clk)
	tester #($size(en_out))::verify_output(en_out, 1'b0);

      // Testcase end
      @(negedge clk) reset = 1;
      @(negedge clk);

      $display("\nSimulation completed with %d errors\n", errors);
      $stop;
   end

endmodule
