// test scenario #1
//resetsim();
//reset_fpga();

// Inputs
`define T1_A_IN1 32'h6a09e667
`define T1_B_IN1 32'hbb67ae85
`define T1_C_IN1 32'h3c6ef372
`define T1_D_IN1 32'ha54ff53a
`define T1_E_IN1 32'h510e527f
`define T1_F_IN1 32'h9b05688c
`define T1_G_IN1 32'h1f83d9ab
`define T1_H_IN1 32'h5be0cd19

`define T1_K1 1024'h1429296706CA6351D5A79147C6E00BF3BF597FC7B00327C8A831C66D983E515276F988DA5CB0A9DC4A7484AA2DE92C6F240CA1CC0FC19DC6EFBE4786E49B69C1C19BF1749BDC06A780DEB1FE72BE5D74550C7DC3243185BE12835B01D807AA98AB1C5ED5923F82A459F111F13956C25BE9B5DBA5B5C0FBCF71374491428A2F98
`define T1_W1 1024'hCEF23042773E4FE9D16CCC0F2759D27027A6CAE51DDD458FB2FF0C9DB3BFFF3DAF840F975DD99DE0F9F4ECC2E8913345E57E7C442AC838A7F86712E5C3BCB09815A907C030CC0782B3D2BACEFD456CD2F5BD2EAB3513260D2CD900FC00000000000000008840290AC93B0C4ED1CA106527A51219F45DD1E9671D0E2F02000000

// Expected outputs
`define T1_A1 32'hBAC2E2D5
`define T1_B1 32'h185247C4
`define T1_C1 32'h9ED6A40F
`define T1_D1 32'h982D896D
`define T1_E1 32'h0F276336
`define T1_F1 32'h608468FC
`define T1_G1 32'h1E824E39
`define T1_H1 32'h85DC7182

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
K = `T1_K1;
W = `T1_W1;
end

repeat(32) @(posedge clk);
//@(posedge en_o) begin
@(negedge clk) begin
	tester #(1)::verify_output(en_o, 1'b1);
	tester #(32)::verify_output(a_o, `T1_A1);
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

$display("\nCompleted testing scenario 1 with %d errors", errors);
