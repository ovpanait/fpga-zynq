`define PERIOD 5

module tb_main();

   // Module instantiation
   reg clk;
   reg reset;
   reg en;
   reg [31:0] a_i, b_i, c_i, d_i, e_i, f_i, g_i, h_i;
   reg [16*32-1:0] K;
   reg [511:0] 	   W;
   wire [31:0] 	   a_o, b_o, c_o, d_o, e_o, f_o, g_o, h_o;
   wire 	   en_o;

   localparam K0 = {
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
`include "test_fc.vh"

   // Auxiliary counters
   integer 	   i;

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
`define T1_A_IN1 32'h6a09e667
`define T1_B_IN1 32'hbb67ae85
`define T1_C_IN1 32'h3c6ef372
`define T1_D_IN1 32'ha54ff53a
`define T1_E_IN1 32'h510e527f
`define T1_F_IN1 32'h9b05688c
`define T1_G_IN1 32'h1f83d9ab
`define T1_H_IN1 32'h5be0cd19

`define T1_W1 512'h15a907c030cc0782b3d2bacefd456cd2f5bd2eab3513260d2cd900fc00000000000000008840290ac93b0c4ed1ca106527a51219f45dd1e9671d0e2f02000000

      // Expected outputs for `DELAY=16
`define T1_A1 32'h75F10351 
`define T1_B1 32'h5556D6F1
`define T1_C1 32'h76B4FBFB
`define T1_D1 32'h6BC5FB7B
      
`define T1_E1 32'h825EF292
`define T1_F1 32'h0F8407F3
`define T1_G1 32'hF7E5F0E6
`define T1_H1 32'hB92243EF

      $display("Begin testing scenario 1...");
      $display("Testing sha round.. ");

      // Testcase init
      wait(reset)
	@(posedge clk);
      @(negedge clk) reset = 0;

      // Testcase
      @(negedge clk) begin
	 en = 1;
	 a_i = `T1_A_IN1;
	 b_i = `T1_B_IN1;
	 c_i = `T1_C_IN1;
	 d_i = `T1_D_IN1;
	 e_i = `T1_E_IN1;
	 f_i = `T1_F_IN1;
	 g_i = `T1_G_IN1;
	 h_i = `T1_H_IN1;
	 K = K0[0 +: 16 * 32];
	 W = `T1_W1;
      end

      repeat(32) @(posedge clk);
      //@(posedge en_o) begin
      @(negedge clk) begin
	 tester #(1)::verify_output(en_o, 1'b1);
	 tester #(32)::verify_output(a_o, `T1_A1);
//	 $display("debug: %H", a_o);	 
	 tester #(32)::verify_output(b_o, `T1_B1);
	 tester #(32)::verify_output(c_o, `T1_C1);
	 tester #(32)::verify_output(d_o, `T1_D1);
	 tester #(32)::verify_output(e_o, `T1_E1);
	 tester #(32)::verify_output(f_o, `T1_F1);
	 tester #(32)::verify_output(g_o, `T1_G1);
	 tester #(32)::verify_output(h_o, `T1_H1);
      end

      @(negedge clk)
	tester #(1)::verify_output(en_o, 1'b0);

      // Testcase end
      @(negedge clk) reset = 1;
      @(negedge clk);

      $display("\nSimulation completed with %d errors\n", errors);
      $stop;
   end

endmodule
