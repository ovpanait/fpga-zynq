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

      // Expected outputs for DELAY=48
`define T1_WRES1 512'h4925b8fe36fe1c250f490962c7e983ff39e21b791fd5fdf2874db8ecc7f75380b1ab527855083d0ebf91b4256b7b1a5efee056a4dda5b9a890504f26ac50ee85

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

	 $finish;
	 
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
