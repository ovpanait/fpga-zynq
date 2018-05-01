`include "sha.vh"

module sha_block(
	     input 		      clk,
	     input 		      reset,
	     input 		      en,

	     input [`WORD_S-1:0]      nonce,
	     input [`MSG_S-1:0]       M,
	     input [`K_SIZE-1:0]      K,
	     input [`H_SIZE-1:0]      H_prev,

	     output [`WORD_S-1:0] nonce_out,
	     output [`H_SIZE-1:0] H,
	     output en_next
	     );

wire [`WARR_S-1:0] W[1:0];
wire [`WORD_S-1:0] tmp[7:0];
wire [`WORD_S-1:0] nonce_tmp[3:0];
wire [`WORD_S-1:0] H_in[7:0];

wire [`H_SIZE-1:0] H_tmp[2:0];

wire en_o[3:0];

// Modules
W_start w_b(
	.clk(clk),
	.reset(reset),
	.en(en),

	.nonce(nonce),
	.M(M),
	.Hin(H_prev),

	.nonce_out(nonce_tmp[0]),
	.W(W[0]),
	.H(H_tmp[0]),
	.en_next(en_o[0]));

W_middle w_e(
	.clk(clk),
	.reset(reset),
	.en(en_o[0]),
	.Win(W[0]),
	.W(W[1]),
	.en_next(en_o[1]));

sha_round round1(
	.clk(clk),
	.reset(reset),
	.en(en_o[0]),

	.nonce(nonce_tmp[0]),
	.a(H_tmp[0][`VEC_I(7)]),
	.b(H_tmp[0][`VEC_I(6)]),
	.c(H_tmp[0][`VEC_I(5)]),
	.d(H_tmp[0][`VEC_I(4)]),
	.e(H_tmp[0][`VEC_I(3)]),
	.f(H_tmp[0][`VEC_I(2)]),
	.g(H_tmp[0][`VEC_I(1)]),
	.h(H_tmp[0][`VEC_I(0)]),
	.Hin(H_tmp[0]),

	.a_next(tmp[0]),
	.b_next(tmp[1]),
	.c_next(tmp[2]),
	.d_next(tmp[3]),
	.e_next(tmp[4]),
	.f_next(tmp[5]),
	.g_next(tmp[6]),
	.h_next(tmp[7]),

	.nonce_out(nonce_tmp[1]),
	.K(K[1023:0]),
	.W(W[0]),
	.H(H_tmp[1]),

	.en_next(en_o[2])
	);

sha_round round2(
	.clk(clk),
	.reset(reset),
	.en(en_o[2]),

	.nonce(nonce_tmp[1]),
	.a(tmp[0]),
	.b(tmp[1]),
	.c(tmp[2]),
	.d(tmp[3]),
	.e(tmp[4]),
	.f(tmp[5]),
	.g(tmp[6]),
	.h(tmp[7]),
	.Hin(H_tmp[1]),

	.nonce_out(nonce_tmp[2]),
	.K(K[2047:1024]),
	.W(W[1]),

	.a_next(H_in[0]),
	.b_next(H_in[1]),
	.c_next(H_in[2]),
	.d_next(H_in[3]),
	.e_next(H_in[4]),
	.f_next(H_in[5]),
	.g_next(H_in[6]),
	.h_next(H_in[7]),
	.H(H_tmp[2]),

	.en_next(en_o[3])
	);

sha_hash hash_out (
	.clk(clk),
	.reset(reset),
	.en(en_o[3]),

	.H_i(H_tmp[2]),
	.nonce(nonce_tmp[2]),

	.a(H_in[0]),
	.b(H_in[1]),
	.c(H_in[2]),
	.d(H_in[3]),
	.e(H_in[4]),
	.f(H_in[5]),
	.g(H_in[6]),
	.h(H_in[7]),

	.nonce_out(nonce_out),
	.H(H),
	.en_o(en_next)
	);

endmodule
