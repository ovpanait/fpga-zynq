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

		    input 		  K,
		    input 		  W,

		    output reg [`W_MAX:0] a_next,
		    output reg [`W_MAX:0] b_next,
		    output reg [`W_MAX:0] c_next,
		    output reg [`W_MAX:0] d_next,
		    output reg [`W_MAX:0] e_next,
		    output reg [`W_MAX:0] f_next,
		    output reg [`W_MAX:0] g_next,
		    output reg [`W_MAX:0] h_next,
		    output reg 		  en_next);

   wire [`W_MAX:0] 			  T1, T2;

   assign T1 = h + `ep1(e) + `ch(e,f,g) + K + W;
   assign T2 = `ep0(a) + `maj(a,b,c);

   // TODO: sync-deassert / async assert reset circuit to be added
   always @(posedge clk)
     begin
	if (reset == 1) begin
	   a_next <= `W_SIZE'd0;
	   b_next <= `W_SIZE'd0;
	   c_next <= `W_SIZE'd0;
	   d_next <= `W_SIZE'd0;
	   e_next <= `W_SIZE'd0;
	   f_next <= `W_SIZE'd0;
	   g_next <= `W_SIZE'd0;
	   h_next <= `W_SIZE'd0;
	   en_next <= 1'd0;
	end // if (reset == 0)
	else if (en == 1) begin
	   h_next <= g;
	   g_next <= f;
	   f_next <= e;
	   e_next <= d + T1;
	   d_next <= c;
	   c_next <= b;
	   b_next <= a;
	   a_next <= T1 + T2;
	   en_next <= 1;
	end // if (en == 1)
     end // always @ (posedge clk, reset)
endmodule // sha256_round
