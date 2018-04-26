// test scenario #1
//resetsim();
//reset_fpga();

// Inputs
`define T1_Win1 1024'hCEF23042773E4FE9D16CCC0F2759D27027A6CAE51DDD458FB2FF0C9DB3BFFF3DAF840F975DD99DE0F9F4ECC2E8913345E57E7C442AC838A7F86712E5C3BCB09815A907C030CC0782B3D2BACEFD456CD2F5BD2EAB3513260D2CD900FC00000000000000008840290AC93B0C4ED1CA106527A51219F45DD1E9671D0E2F02000000

// Expected outputs
`define T1_WRES1 1024'h4925b8fe36fe1c250f490962c7e983ff39e21b791fd5fdf2874db8ecc7f75380b1ab527855083d0ebf91b4256b7b1a5efee056a4dda5b9a890504f26ac50ee85b61bfa564e66030cd9cfe90bd04e81ebf54947cd08c3595980e92b6788ae4b3035d81fc12d4d1df3aae2658a8c69f2898206b7da74f07f2db984387675156a80

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
