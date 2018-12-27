`include "sha.vh"

/*
 * Module for generating bitcoin block. (SHA256(SHA256(bitcoin block header))
 */

/*
 * Bitcoin block header reference
 * https://bitcoin.org/en/developer-reference#block-headers
 */

module bitcoin_block (
		      input 		     clk,
		      input 		     reset,
		      input 		     start,

		      input [`VERSION_S-1:0] blk_version,
		      input [`H_SIZE-1:0]    prev_blk_header_hash,
		      input [`H_SIZE-1:0]    merkle_root_hash,
		      input [`TIME_S-1:0]    blk_time,
		      input [`NBITS_S-1:0]   blk_nbits,
		      input [`WORD_S-1:0]    blk_nonce,

		      output [`H_SIZE-1:0]   bitcoin_blk,
		      output [`WORD_S-1:0]   bitcoin_nonce,
		      output 		     bitcoin_done
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

   wire [`H_SIZE-1:0] 			     H_tmp[1:0];
   wire 				     en_tmp[1:0];
   wire [`WORD_S-1:0] 			     nonce_tmp[1:0];

   sha_block block1(
		    .clk(clk),
		    .reset(reset),
		    .en(start),

		    .nonce(blk_nonce),
		    .K(K),
		    .M({blk_version, prev_blk_header_hash, merkle_root_hash[`H_SIZE -1:4 * 8]}),
		    .H_prev(H0),

		    .nonce_out(nonce_tmp[0]),
		    .H(H_tmp[0]),
		    .en_next(en_tmp[0])
		    );
   
   sha_block block2(
		    .clk(clk),
		    .reset(reset),
		    .en(en_tmp[0]),

		    .nonce(nonce_tmp[0]),
		    .K(K),
		    .M({merkle_root_hash[4* 8 - 1: 0], blk_time, blk_nbits, nonce_tmp[0], padding_512}),
		    .H_prev(H_tmp[0]),

		    .nonce_out(nonce_tmp[1]),
		    .H(H_tmp[1]),
		    .en_next(en_tmp[1])
		    );

   sha_block block3(
		    .clk(clk),
		    .reset(reset),
		    .en(en_tmp[1]),

		    .nonce(nonce_tmp[1]),
		    .K(K),
		    .M({H_tmp[1], padding_256}),
		    .H_prev(H0),

		    .nonce_out(bitcoin_nonce),
		    .H(bitcoin_blk),
		    .en_next(bitcoin_done)
		    );
endmodule
