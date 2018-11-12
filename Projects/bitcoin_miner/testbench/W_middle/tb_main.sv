`timescale 1ns/1ns
`define PERIOD 5

module tb_main();

   // Module instantiation
   reg clk;
   reg reset;
   reg en;
   reg [511:0] Win;
   wire [511:0] W;
   wire 	 en_out;

   W_middle DUT (
		 .clk(clk),
		 .reset(reset),
		 .en(en),
		 .Win(Win),
		 .W(W),
		 .en_next(en_out)
		 );

   // Test functions
`include "test_fc.vh"

   // Auxiliary counters
   integer 	 i;

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
`define T1_Win1 512'h15a907c030cc0782b3d2bacefd456cd2f5bd2eab3513260d2cd900fc00000000000000008840290ac93b0c4ed1ca106527a51219f45dd1e9671d0e2f02000000

      // Expected outputs for DELAY=16
`define T1_WRES1 512'hcef23042773e4fe9d16ccc0f2759d27027a6cae51ddd458fb2ff0c9db3bfff3daf840f975dd99de0f9f4ecc2e8913345e57e7c442ac838a7f86712e5c3bcb098

      $display("Begin testing scenario 1...");
      $display("Testing W output and number of clock cycles... ");

      // Testcase init
      wait(reset)
	@(posedge clk);
      @(negedge clk) reset = 0;

      // Testcase
      @(negedge clk) begin
	 en = 1;
	 Win = `T1_Win1;
      end

      @(posedge en_out);
      
      @(negedge clk) begin
	 tester #(1)::verify_output(en_out, 1'b1);
	 tester #($size(W))::verify_output(W, `T1_WRES1);
      end

      @(negedge clk)
	tester #(1)::verify_output(en_out, 1'b0);

      // Testcase end
      @(negedge clk) reset = 1;
      @(negedge clk);

       $display("\nSimulation completed with %d errors\n", errors);
      $stop;
   end

endmodule
