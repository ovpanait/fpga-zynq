`include "sha.vh"

module sha_hash (
		  input clk,
		  input reset,
		  input en,

		  input [`WORD_S-1:0] nonce,
		  input [`H_SIZE-1:0] H_i,
		  input [`WORD_S-1:0] a,
		  input [`WORD_S-1:0] b,
		  input [`WORD_S-1:0] c,
		  input [`WORD_S-1:0] d,
		  input [`WORD_S-1:0] e,
		  input [`WORD_S-1:0] f,
		  input [`WORD_S-1:0] g,
		  input [`WORD_S-1:0] h,

		   output reg [`WORD_S-1:0] nonce_out,
		  output reg en_o,
		  output reg [`H_SIZE-1:0] H
		  );

always @(posedge clk) begin
	en_o <= 0;
	if (reset == 1) begin
		H <= {`H_SIZE{1'b0}};
		nonce_out <= {`WORD_S{1'b0}};
	end else if (en == 1) begin
		H[`VEC_I(0)] <= H_i[`VEC_I(0)] + h;
		H[`VEC_I(1)] <= H_i[`VEC_I(1)] + g;
		H[`VEC_I(2)] <= H_i[`VEC_I(2)] + f;
		H[`VEC_I(3)] <= H_i[`VEC_I(3)] + e;
		H[`VEC_I(4)] <= H_i[`VEC_I(4)] + d;
		H[`VEC_I(5)] <= H_i[`VEC_I(5)] + c;
		H[`VEC_I(6)] <= H_i[`VEC_I(6)] + b;
		H[`VEC_I(7)] <= H_i[`VEC_I(7)] + a;
		nonce_out <= nonce;
		en_o <= 1;
	end
end
endmodule
