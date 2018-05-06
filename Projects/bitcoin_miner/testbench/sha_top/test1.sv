// test scenario #1
//resetsim();
//reset_fpga();

// Inputs
`define T1_PREV_BLK1 256'h0000000000000000A2940884E0C3BC96510CAD11912A527E9D15DF42F0E1D672
`define T1_PREV_H1 256'h09A0D19192EF77C304FE447888F9EF5069D648465A19146FB770619714D08904
`define T1_INPUT_M1 96'h45F4992E74749054747B1B18

// Expected outputs
`define T1_RES1 256'h3EBB2D68D7007148B184E57BBA9697D76BC04141155C57F97E3B92C5FD6A46BD

$display("Begin testing scenario 1...");
$display("Testing sha block hash output.. ");

// Testcase init
wait(reset)
@(posedge clk);
@(negedge clk) reset = 0;

// Testcase
@(negedge clk) begin
en = 1;
input_M = `T1_INPUT_M1;
prev_H = `T1_PREV_H1;
//prev_blk = {256{1'b1}};
prev_blk = `T1_PREV_BLK1;
end
@(negedge clk) en = 0;

// Test output for 1st input
//repeat(128) @(posedge clk);
@(posedge found);
@(negedge clk) begin
	//tester #(256)::verify_output(H, `T1_H1);
	$display("nonce: %h", nonce);
	$display("winner H: %h", winner_H);
end

repeat(5000) @(posedge clk);
en = 1;

@(posedge clk);
en = 0;

@ (posedge done);
@(negedge clk) begin
	//tester #(256)::verify_output(H, `T1_H1);
	$display("nonce: %h", nonce);
	$display("winner H: %h", winner_H);
end

// Testcase end
@(negedge clk) reset = 1;
@(negedge clk);

$display("\nCompleted testing scenario 1 with %d errors", errors);
