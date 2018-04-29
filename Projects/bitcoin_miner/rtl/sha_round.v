`include "sha.vh"

module sha_round(
		    input 		  clk,
		    input 		  reset,
		    input 		  en,

		    input [`W_MAX:0] 	  a,
		    input [`W_MAX:0] 	  b,
		    input [`W_MAX:0] 	  c,
		    input [`W_MAX:0] 	  d,
		    input [`W_MAX:0] 	  e,
		    input [`W_MAX:0] 	  f,
		    input [`W_MAX:0] 	  g,
		    input [`W_MAX:0] 	  h,

		    input [`WARR_S-1:0]	  K,
		    input [`WARR_S-1:0]	  W,

		    output reg [`W_MAX:0] a_next,
		    output reg [`W_MAX:0] b_next,
		    output reg [`W_MAX:0] c_next,
		    output reg [`W_MAX:0] d_next,
		    output reg [`W_MAX:0] e_next,
		    output reg [`W_MAX:0] f_next,
		    output reg [`W_MAX:0] g_next,
		    output reg [`W_MAX:0] h_next,
		    output reg 		  en_next);

   wire [`WORD_S-1:0] 		      W_arr[`W_BLKCNT-1:0];
   wire [`WORD_S-1:0] 		      K_arr[`W_BLKCNT-1:0];

   wire [`W_MAX:0] 			  T1_i, T2_i;
   wire [`W_MAX:0] 			  T1_reg, T2_reg;
   reg [4:0] 				  counter;

   genvar 			      i;

   generate
      for (i=0; i < `W_BLKCNT; i=i+1) begin : WIN_ARR
	 assign  W_arr[i] = W[(i+1)*32 - 1:i*32];
      end
   endgenerate

   generate
      for (i=0; i < `W_BLKCNT; i=i+1) begin : KIN_ARR
	 assign  K_arr[i] = K[(i+1)*32 - 1:i*32];
      end
   endgenerate

   assign   T1_i = h + `ep1(e) + `ch(e,f,g) + K_arr[counter] + W_arr[counter];
   assign   T2_i = `ep0(a) + `maj(a,b,c);

   assign   T1_reg = h_next + `ep1(e_next) + `ch(e_next, f_next, g_next) + K_arr[counter] + W_arr[counter];
   assign   T2_reg = `ep0(a_next) + `maj(a_next, b_next, c_next);

   always @(posedge clk)
     begin
	en_next <= 0;
	if (reset == 1) begin
	   counter <= 5'h0;
	   a_next <= `W_SIZE'd0;
	   b_next <= `W_SIZE'd0;
	   c_next <= `W_SIZE'd0;
	   d_next <= `W_SIZE'd0;
	   e_next <= `W_SIZE'd0;
	   f_next <= `W_SIZE'd0;
	   g_next <= `W_SIZE'd0;
	   h_next <= `W_SIZE'd0;
	end // if (reset == 0)
	else if (counter != 5'h0  || (en == 1 && counter == 5'h0)) begin
	   counter <= counter + 5'h1;

	   if (counter == 5'h0) begin
	      h_next <= g;
	      g_next <= f;
	      f_next <= e;
	      e_next <= d + T1_i;
	      d_next <= c;
	      c_next <= b;
	      b_next <= a;
	      a_next <= T1_i + T2_i;
	   end
	   else begin
	      if (counter == 5'h1F) begin
		 en_next <= 1;
		 counter <= 5'h0;
	      end
	      h_next <= g_next;
	      g_next <= f_next;
	      f_next <= e_next;
	      e_next <= d_next + T1_reg;
	      d_next <= c_next;
	      c_next <= b_next;
	      b_next <= a_next;
	      a_next <= T1_reg + T2_reg;
	   end
	end // if (en == 1)
     end // always @ (posedge clk, reset)
endmodule // sha256_round
