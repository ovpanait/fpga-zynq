// test scenario #1
//resetsim();
//reset_fpga();

// Inputs
`define T1_AIN1 32'h6a09e667
`define T1_BIN1 32'hbb67ae85
`define T1_CIN1 32'h3c6ef372
`define T1_DIN1 32'ha54ff53a
`define T1_EIN1 32'h510e527f
`define T1_FIN1 32'h9b05688c
`define T1_GIN1 32'h1f83d9ab
`define T1_HIN1 32'h5be0cd19

`define T1_K1 32'h
`define T1_W1 32'h

// Expected outputs
`define T1_A1 32'hFE08884D
`define T1_B1 32'h6A09E667
`define T1_C1 32'hBB67AE85
`define T1_D1 32'h3C6EF372
`define T1_E1 32'h9AC7E2A2
`define T1_F1 32'h510E527F
`define T1_G1 32'h9B05688C
`define T1_H1 32'h1F83D9AB

$display("Begin testing scenario 1...");
$display("Testing W output and number of clock cycles... ");

// Testcase init
wait(reset)
@(posedge clk);
@(negedge clk) reset = 0;

// Testcase
//repeat(50000000) @(posedge clk);
@(negedge clk) begin
a = `T1_AIN1;
b - `T1_BIN1;
c = `T1_CIN1;
d = `T1_DIN1;
e = `T1_EIN1;
f = `T1_FIN1;
g = `T1_GIN1;
h = `T1_HIN1;
end

repeat(32) @(posedge clk);
@(negedge clk) begin
	tester #(1)::verify_output(en_out, 1'b1);
	tester #(1024)::verify_output(W, `T1_WRES1);
end

@(negedge clk)
	tester #(1)::verify_output(en_out, 1'b0);

// Testcase end
@(negedge clk) reset = 1;
@(negedge clk);

$display("\nCompleted testing scenario 1 with %d errors", errors);
