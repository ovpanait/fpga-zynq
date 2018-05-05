`include "sha.vh"

module sha_top (
	input clk,
	input reset,
	input en,

	input [`H_SIZE-1:0] prev_blk,
	input [`H_SIZE-1:0] prev_H,
	input [`INPUT_S-1:0] input_M,

	output reg [`WORD_S-1:0] nonce,
	output reg [`H_SIZE-1:0] winner_H,
	output reg done,
	output reg found
	);

localparam K = {
	32'hC67178F2, 32'hBEF9A3F7, 32'hA4506CEB, 32'h90BEFFFA,
	32'h8CC70208, 32'h84C87814, 32'h78A5636F, 32'h748F82EE,
	32'h682E6FF3, 32'h5B9CCA4F, 32'h4ED8AA4A, 32'h391C0CB3,
	32'h34B0BCB5, 32'h2748774C, 32'h1E376C08, 32'h19A4C116,
	32'h106AA070, 32'hF40E3585, 32'hD6990624, 32'hD192E819,
	32'hC76C51A3, 32'hC24B8B70, 32'hA81A664B, 32'hA2BFE8A1,
	32'h92722C85, 32'h81C2C92E, 32'h766A0ABB, 32'h650A7354,
	32'h53380D13, 32'h4D2C6DFC, 32'h2E1B2138, 32'h27B70A85,
	32'h14292967, 32'h06CA6351, 32'hD5A79147, 32'hC6E00BF3,
	32'hBF597FC7, 32'hB00327C8, 32'hA831C66D, 32'h983E5152,
	32'h76F988DA, 32'h5CB0A9DC, 32'h4A7484AA, 32'h2DE92C6F,
	32'h240CA1CC, 32'h0FC19DC6, 32'hEFBE4786, 32'hE49B69C1,
	32'hC19BF174, 32'h9BDC06A7, 32'h80DEB1FE, 32'h72BE5D74,
	32'h550C7DC3, 32'h243185BE, 32'h12835B01, 32'hD807AA98,
	32'hAB1C5ED5, 32'h923F82A4, 32'h59F111F1, 32'h3956C25B,
	32'hE9B5DBA5, 32'hB5C0FBCF, 32'h71374491, 32'h428A2F98
	};


localparam H0 = {
	32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
	32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
	};

localparam padding_512 = 384'h800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000280;
localparam padding_256 = 256'h8000000000000000000000000000000000000000000000000000000000000100;

localparam 	ready = 1'b0, // waiting for input
		proc = 1'b1; // feeding the pipeline

wire [`H_SIZE-1:0] H_tmp;
wire [`H_SIZE-1:0] H_final;
wire en_tmp[1:0];
wire [`WORD_S-1:0] nonce_tmp;

wire hash_done;
wire [`WORD_S-1:0] hash_nonce;

reg start;
reg [`WORD_S-1:0] nonce_reg;
reg [5:0] cnt;

reg state;

sha_block block1(
	.clk(clk),
	.reset(reset),
	.en(start),

	.nonce(nonce_reg),
	.K(K),
	.M({input_M, nonce_reg, padding_512}),
	.H_prev(prev_H),

	.nonce_out(nonce_tmp),
	.H(H_tmp),
	.en_next(en_tmp[0])
	);

sha_block block2(
	.clk(clk),
	.reset(reset),
	.en(en_tmp[0]),

	.nonce(nonce_tmp),
	.K(K),
	.M({H_tmp, padding_256}),
	.H_prev(H0),

	.nonce_out(hash_nonce),
	.H(H_final),
	.en_next(hash_done)
	);

always @(posedge clk) begin
	if (reset == 1) begin
		nonce <= {`WORD_S{1'b0}};
		done <= 0;
		found <= 0;
		start <= 0;
		cnt <= 6'h0;
		state <= ready;
	end else
		start <= 0;
		case (state)
			ready:
				if (en == 1) begin
					//nonce_reg <= {`WORD_S{1'b0}};
					nonce_reg <= 32'h43F740C0;
					start <= 1;
					done <= 0;
					found <= 0;
					cnt <= 6'h0;
					state <= proc;
				end
			proc: begin
				cnt <= cnt + 1;
				if (hash_done == 1 &&  `CH_HASH(H_final) < prev_blk) begin
					done <= 1;
					found <= 1;
					nonce <= hash_nonce;
					winner_H <= `CH_HASH(H_final);
					state <= ready;
				end

				if (cnt == 6'h20) begin
					if (nonce_reg == {`WORD_S{1'b1}}) begin
						done <= 1;
						state <= ready;
					end else begin
						nonce_reg <= nonce_reg + 1;
						start <= 1;
					end
				cnt <= 6'h0;
				end
			end
		endcase
end
endmodule
