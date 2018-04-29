`include "sha.vh"

module sha_hash (
		  input clk,
		  input reset,
		  input en_H,
		  input en_regs,

		  input [`H_SIZE-1:0] H_prev,
		  input [`WORD_S-1:0] a,
		  input [`WORD_S-1:0] b,
		  input [`WORD_S-1:0] c,
		  input [`WORD_S-1:0] d,
		  input [`WORD_S-1:0] e,
		  input [`WORD_S-1:0] f,
		  input [`WORD_S-1:0] g,
		  input [`WORD_S-1:0] h,

		  output reg en_o,
		  output reg [`H_SIZE-1:0] H
		  );

reg [5:0] cnt;

always @(posedge clk) begin
	en_o <= 0;
	if (reset == 1) begin
		H <= {`H_SIZE{1'b0}};
	end else if (en_H == 1) begin
		for(cnt = 5'h0; cnt < `H_BLKCNT; cnt = cnt + 5'h1)
			H[`VEC_I(cnt)] <= H_prev[`VEC_I(cnt)];
	end else if (en_regs == 1) begin
		H[`VEC_I(0)] <= H[`VEC_I(0)] + h;
		H[`VEC_I(1)] <= H[`VEC_I(1)] + g;
		H[`VEC_I(2)] <= H[`VEC_I(2)] + f;
		H[`VEC_I(3)] <= H[`VEC_I(3)] + e;
		H[`VEC_I(4)] <= H[`VEC_I(4)] + d;
		H[`VEC_I(5)] <= H[`VEC_I(5)] + c;
		H[`VEC_I(6)] <= H[`VEC_I(6)] + b;
		H[`VEC_I(7)] <= H[`VEC_I(7)] + a;
		en_o <= 1;
	end
end
endmodule
