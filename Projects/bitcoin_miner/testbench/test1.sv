// test scenario #1
//resetsim();
//reset_fpga();

// Inputs
`define T1_M1 512'h02000000671D0E2FF45DD1E927A51219D1CA1065C93B0C4E8840290A00000000000000002CD900FC3513260DF5BD2EABFD456CD2B3D2BACE30CC078215A907C0

// Expected outputs
`define T1_WRES1 1024'hCEF23042773E4FE9D16CCC0F2759D27027A6CAE51DDD458FB2FF0C9DB3BFFF3DAF840F975DD99DE0F9F4ECC2E8913345E57E7C442AC838A7F86712E5C3BCB09815A907C030CC0782B3D2BACEFD456CD2F5BD2EAB3513260D2CD900FC00000000000000008840290AC93B0C4ED1CA106527A51219F45DD1E9671D0E2F02000000

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
