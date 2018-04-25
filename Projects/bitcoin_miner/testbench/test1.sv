// test scenario #1
//resetsim();
//reset_fpga();

// Inputs
`define T1_M1 512'h02000000671D0E2FF45DD1E927A51219D1CA1065C93B0C4E8840290A00000000000000002CD900FC3513260DF5BD2EABFD456CD2B3D2BACE30CC078215A907C0

// Expected outputs
`define T1_WRES1 1024'h02000000671D0E2FF45DD1E927A51219D1CA1065C93B0C4E8840290A00000000000000002CD900FC3513260DF5BD2EABFD456CD2B3D2BACE30CC078215A907C0C3BCB098F86712E52AC838A7E57E7C44E8913345F9F4ECC25DD99DE0AF840F97B3BFFF3DB2FF0C9D1DDD458F27A6CAE52759D270D16CCC0F773E4FE9CEF23042

$display("Begin testing scenario 1... \n");
$display("Testing W output values... ");

// Testcase init
wait(reset)
@(posedge clk);
@(negedge clk) reset = 0;

// Testcase
//repeat(50000000) @(posedge clk);
@(negedge clk) begin
en = 1;
M = `T1_M1;
end

@(posedge en_out)
tester #(1024)::verify_output(W, `T1_WRES1);

// Testcase end
reset = 1;
@(negedge clk);

$display("\nCompleted testing scenario 1 with %d errors", errors);
