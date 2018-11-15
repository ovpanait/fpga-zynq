`timescale 1ns/1ns
`define PERIOD 5

module tb_main();

   // Module instantiation
   reg clk;
   reg reset;
   reg en;
   reg [31:0] nonce;
   reg [511:0] M;

   wire [255:0] H;
   wire 	en_o;
   wire [31:0] 	nonce_out;

   localparam K = {
		   32'hC67178F2, 32'hBEF9A3F7, 32'hA4506CEB, 32'h90BEFFFA,
		   32'h8CC70208, 32'h84C87814, 32'h78A5636F, 32'h748F82EE,
		   32'h682E6FF3, 32'h5B9CCA4F, 32'h4ED8AA4A, 32'h391C0CB3,
		   32'h34B0BCB5, 32'h2748774C, 32'h1E376C08, 32'h19A4C116,
		   32'h106AA070, 32'hF40E3585, 32'hD6990624, 32'hD192E819,
		   32'hC76C51A3, 32'hC24B8B70, 32'hA81A664B, 32'hA2BFE8A1,
		   32'h92722C85, 32'h81C2C92E, 32'h766A0ABB, 32'h650A7354,
		   32'h53380D13, 32'h4D2C6DFC, 32'h2E1B2138, 32'h27B70A85,
		   32'h14292967, 32'h06CA6351, 32'hD5A79147, 32'hC6E00BF3,
		   32'hBF597FC7, 32'hB00327C8, 32'hA831C66D, 32'h983E5152,
		   32'h76F988DA, 32'h5CB0A9DC, 32'h4A7484AA, 32'h2DE92C6F,
		   32'h240CA1CC, 32'h0FC19DC6, 32'hEFBE4786, 32'hE49B69C1,
		   32'hC19BF174, 32'h9BDC06A7, 32'h80DEB1FE, 32'h72BE5D74,
		   32'h550C7DC3, 32'h243185BE, 32'h12835B01, 32'hD807AA98,
		   32'hAB1C5ED5, 32'h923F82A4, 32'h59F111F1, 32'h3956C25B,
		   32'hE9B5DBA5, 32'hB5C0FBCF, 32'h71374491, 32'h428A2F98
		   };
   
   localparam H0 = {
		    32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
		    32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
		    };
   
   sha_block DUT (
		  .clk(clk),
		  .reset(reset),
		  .en(en),

		  .nonce(nonce),
		  .K(K),
		  .M(M),
		  .H_prev(H0),

		  .nonce_out(nonce_out),
		  .H(H),
		  .en_next(en_o)
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
`define T1_M2 512'h45F4992E74749054747B1B1843F740C0800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000280

      // Expected outputs
`define T1_H1 256'h09A0D19192EF77C304FE447888F9EF5069D648465A19146FB770619714D08904
`define T1_H2 256'hF4A4F82759D9117B8714F483DB052DA41B1D147424E315F86BB97C82B87254E3

      $display("Begin testing scenario 1...");
      $display("Testing sha block hash output.. ");

      // Testcase init
      wait(reset)
	@(posedge clk);
      @(negedge clk) reset = 0;

      // Testcase
      @(negedge clk) begin
	 en = 1;
	 nonce = 32'h11;
	 
	 M = `T1_M1;
      end

`define TEST_DUT DUT.rounds2[2].round
`define MID_DUT DUT.middle_layers[2].w_e
      @(negedge clk) en = 0;
      // Test output for 1st input
      //      @(posedge DUT.en_o[4]);
      @(posedge en_o);
      @(negedge clk) begin
	 /*	 $display("xxx3: %H", `TEST_DUT.a);
	  $display("xxx3: %H", `TEST_DUT.b);
	  $display("xxx3: %H", `TEST_DUT.c);
	  $display("xxx3: %H", `TEST_DUT.d);
	  $display("xxx3: %H", `TEST_DUT.e);
	  $display("xxx3: %H", `TEST_DUT.f);
	  $display("xxx3: %H", `TEST_DUT.g);
	  $display("xxx3: %H", `TEST_DUT.h);
	  
	  $display("xxx3: %H", `TEST_DUT.K);

	  for (int i = 0 ; i < 16; i=i+1)
	  $display("xxx4: W[%d]: %H", i, `TEST_DUT.W[i*32 +: 32]);

	  $display("xxx3: %H", `TEST_DUT.K_arr);
	  for (int i = 0 ; i < 16; i=i+1)
	  $display("xxx4: W_arr[%d]: %H", i, `TEST_DUT.W_arr[i]);
	  
	  for (int i = 0 ; i < 16; i=i+1)
	  $display("xxx4: W_middle[%d]: %H", i, `MID_DUT.W_arr[i]);
	  for (int i = 0 ; i < 16; i=i+1)
	  $display("xxx4: W_middle_in[%d]: %H", i, `MID_DUT.Win[i*32 +: 32]);

	  $display("xxx3: %H", `TEST_DUT.a_next);
	  $display("xxx3: %H", `TEST_DUT.b_next);
	  $display("xxx3: %H", `TEST_DUT.c_next);
	  $display("xxx3: %H", `TEST_DUT.d_next);
	  $display("xxx3: %H", `TEST_DUT.e_next);
	  $display("xxx3: %H", `TEST_DUT.f_next);
	  $display("xxx3: %H", `TEST_DUT.g_next);
	  $display("xxx3: %H", `TEST_DUT.h_next);
	  $display("xxx3: %H", `TEST_DUT.en_next);
	  */	 
	 tester #(1)::verify_output(en_o, 1'b1);
	 tester #($size(H))::verify_output(H, `T1_H1);
	 tester #($size(nonce_out))::verify_output(nonce_out, 32'h11);

	 //	 $finish;
	 
      end // @ (posedge en_o)
      @(posedge clk);
      @(negedge clk)
	tester #(1)::verify_output(en_o, 1'b0);

      // Test output for 2nd input
      en = 1'b1;
      M = `T1_M2;
      @(posedge en_o);
      @(negedge clk) begin
	 tester #(1)::verify_output(en_o, 1'b1);
	 tester #($size(H))::verify_output(H, `T1_H2);
      end
      @(negedge clk)
	tester #(1)::verify_output(en_o, 1'b0);

      // Testcase end
      @(negedge clk) reset = 1;
      @(negedge clk);

      $display("\nSimulation completed with %d errors\n", errors);
      $stop;
      
   end

   /*   always @(`TEST_DUT.counter)
    begin
    $display("counter: %H", `TEST_DUT.counter);

    $display("xxx3: %H", `TEST_DUT.a);
    $display("xxx3: %H", `TEST_DUT.b);
    $display("xxx3: %H", `TEST_DUT.c);
    $display("xxx3: %H", `TEST_DUT.d);
    $display("xxx3: %H", `TEST_DUT.e);
    $display("xxx3: %H", `TEST_DUT.f);
    $display("xxx3: %H", `TEST_DUT.g);
    $display("xxx3: %H", `TEST_DUT.h);
    $display("");
    $display("xxx3: %H", `TEST_DUT.a_next);
    $display("xxx3: %H", `TEST_DUT.b_next);
    $display("xxx3: %H", `TEST_DUT.c_next);
    $display("xxx3: %H", `TEST_DUT.d_next);
    $display("xxx3: %H", `TEST_DUT.e_next);
    $display("xxx3: %H", `TEST_DUT.f_next);
    $display("xxx3: %H", `TEST_DUT.g_next);
    $display("xxx3: %H", `TEST_DUT.h_next);
    $display("xxx3: %H", `TEST_DUT.en_next);
     end
    */
endmodule
