`include "sha.vh"

module sha_block(
		 input 		      clk,
		 input 		      reset,
		 input 		      en,

		 input [`WORD_S-1:0]  nonce,
		 input [`MSG_S-1:0]   M,
		 input [`K_SIZE-1:0]  K,
		 input [`H_SIZE-1:0]  H_prev,

		 output [`WORD_S-1:0] nonce_out, 
		 output [`H_SIZE-1:0] H,
		 output 	      en_next
		 );

   wire [`WARR_S-1:0] 		      W[64/`DELAY+1:0];
   wire 			      en_o[2*64/`DELAY:0];
   wire [`WORD_S-1:0] 		      nonce_tmp[2*64/`DELAY:0];

   wire [`H_SIZE-1:0] 		      H_tmp[64/`DELAY:0];
   wire [`WORD_S-1:0] 		      tmp[64/`DELAY:0];
   wire [`WORD_S-1:0] 		      abc_tmp[64/`DELAY:0][7:0];

   genvar 			      i;
   
   // W[0] = reverse(M)
   generate
      for (i = 0; i < `WARR_S / `W_SIZE; i=i+1) begin
	 assign W[0][i*`W_SIZE +: `W_SIZE] = M[`WARR_S - (i+1)*`W_SIZE +: `W_SIZE]; 
      end
   endgenerate

   assign en_o[0] = en;
   
   W_start w_b(
	       .clk(clk),
	       .reset(reset),
	       .en(en_o[0]),

	       .W_in(W[0]),

	       .W(W[16/`DELAY]),
	       .en_next(en_o[1]));

   reg [`H_SIZE-1:0] H_delay;
   reg [`WORD_S-1:0] nonce_delay;
   
   always @(posedge clk) begin
      if (en == 1'b1) begin
	 H_delay <= H_prev;
	 nonce_delay <= nonce;
      end
   end

   assign nonce_tmp[0] = nonce_delay;

   generate
      for (i = 0; i < `H_SIZE / `W_SIZE; i=i+1) begin
	 assign H_tmp[0][i*`W_SIZE +: `W_SIZE] = H_delay[i*`W_SIZE +: `W_SIZE]; 
      end
   endgenerate

   generate
      for (i = 0; i < 48/`DELAY; i=i+1) begin : middle_layers
	 W_middle w_e(
		      .clk(clk),
		      .reset(reset),
		      .en(en_o[16/`DELAY+i]),
		      .Win(W[16/`DELAY+i]),
	    
		      .W(W[16/`DELAY+i+1])
		      );
      end
   endgenerate

   // SHA ROUNDS
   generate
      for (i = 0; i < 8; i=i+1) begin
	 assign  abc_tmp[0][7 - i] = H_tmp[0][i*`W_SIZE +: `W_SIZE]; // shit
      end
   endgenerate

   generate     
      for (i = 0; i < 16/`DELAY; i=i+1) begin : rounds1
	 sha_round round(
			 .clk(clk),
			 .reset(reset),
			 .en(en_o[i+1]),

			 .nonce(nonce_tmp[i]),
			 .a(abc_tmp[i][0]),
			 .b(abc_tmp[i][1]),
			 .c(abc_tmp[i][2]),
			 .d(abc_tmp[i][3]),
			 .e(abc_tmp[i][4]),
			 .f(abc_tmp[i][5]),
			 .g(abc_tmp[i][6]),
			 .h(abc_tmp[i][7]),
			 .Hin(H_tmp[i]),

			 .nonce_out(nonce_tmp[i+1]),
			 .K(K[i*(`DELAY*`W_SIZE) +: `DELAY*`W_SIZE]),
			 .W(W[16/`DELAY] >> i*`DELAY*`WORD_S), // FUCK: left vs right shift..

			 .a_next(abc_tmp[i+1][0]),
			 .b_next(abc_tmp[i+1][1]),
			 .c_next(abc_tmp[i+1][2]),
			 .d_next(abc_tmp[i+1][3]),
			 .e_next(abc_tmp[i+1][4]),
			 .f_next(abc_tmp[i+1][5]),
			 .g_next(abc_tmp[i+1][6]),
			 .h_next(abc_tmp[i+1][7]),
			 .H(H_tmp[i+1]),

			 .en_next(en_o[i+2])
			 );
      end
   endgenerate

   generate      
      for (i = 16/`DELAY; i < 64/`DELAY; i=i+1) begin : rounds2
	 sha_round #(.LEFT(0)) round 
	       (
		.clk(clk),
		.reset(reset),
		.en(en_o[i+1]),

		.nonce(nonce_tmp[i]),
		.a(abc_tmp[i][0]),
		.b(abc_tmp[i][1]),
		.c(abc_tmp[i][2]),
		.d(abc_tmp[i][3]),
		.e(abc_tmp[i][4]),
		.f(abc_tmp[i][5]),
		.g(abc_tmp[i][6]),
		.h(abc_tmp[i][7]),
		.Hin(H_tmp[i]),

		.nonce_out(nonce_tmp[i+1]),
		.K(K[i*(`DELAY*`W_SIZE) +: `DELAY*`W_SIZE]),
		.W(W[i+1]),

		.a_next(abc_tmp[i+1][0]),
		.b_next(abc_tmp[i+1][1]),
		.c_next(abc_tmp[i+1][2]),
		.d_next(abc_tmp[i+1][3]),
		.e_next(abc_tmp[i+1][4]),
		.f_next(abc_tmp[i+1][5]),
		.g_next(abc_tmp[i+1][6]),
		.h_next(abc_tmp[i+1][7]),
		.H(H_tmp[i+1]),

		.en_next(en_o[i+2])
		);
      end
   endgenerate

   sha_hash hash_out (
		      .clk(clk),
		      .reset(reset),
		      .en(en_o[64/`DELAY+1]),

		      .H_i(H_tmp[64/`DELAY]),
		      .nonce(nonce_tmp[64/`DELAY]),

		      .a(abc_tmp[64/`DELAY][0]),
		      .b(abc_tmp[64/`DELAY][1]),
		      .c(abc_tmp[64/`DELAY][2]),
		      .d(abc_tmp[64/`DELAY][3]),
		      .e(abc_tmp[64/`DELAY][4]),
		      .f(abc_tmp[64/`DELAY][5]),
		      .g(abc_tmp[64/`DELAY][6]),
		      .h(abc_tmp[64/`DELAY][7]),

		      .nonce_out(nonce_out),
		      .H(H),
		      .en_o(en_next)
		      );
   
endmodule
