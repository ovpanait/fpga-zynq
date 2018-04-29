// test scenario #1
//resetsim();
//reset_fpga();

// Inputs
`define T1_M1 512'h02000000671D0E2FF45DD1E927A51219D1CA1065C93B0C4E8840290A00000000000000002CD900FC3513260DF5BD2EABFD456CD2B3D2BACE30CC078215A907C0

// Expected outputs
`define T1_H1 256'h09A0D19192EF77C304FE447888F9EF5069D648465A19146FB770619714D08904

$display("Begin testing scenario 1...");
$display("Testing sha block hash output.. ");

// Testcase init
wait(reset)
@(posedge clk);
@(negedge clk) reset = 0;

// Testcase
@(negedge clk) begin
en = 1;
M = `T1_M1;
end

@(negedge clk) en = 0;

repeat(128) @(posedge clk);
//@(posedge en_o) begin
@(negedge clk) begin
	tester #(1)::verify_output(en_o, 1'b1);
	tester #(256)::verify_output(H, `T1_H1);
end

@(negedge clk)
	tester #(1)::verify_output(en_o, 1'b0);

// Testcase end
@(negedge clk) reset = 1;
@(negedge clk);

$display("\nCompleted testing scenario 1 with %d errors", errors);
