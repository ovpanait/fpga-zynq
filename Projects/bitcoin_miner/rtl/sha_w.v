`include "sha.vh"

module sha_w(
	     input 		      clk,
	     input 		      reset,
	     input 		      en,
	     input [`MSG_S-1:0]       M,

	     output reg [`WARR_S-1:0] W,
	     output reg 	      en_next
	     );

   wire [`WORD_S-1:0] 		      Min_arr[`MSG_BLKCNT - 1:0];
   wire [`WORD_S-1:0] 		      W_arr[`W_BLKCNT-1:0];

   reg [5:0] 			      cnt = 6'h0;

   genvar 			      i;

   generate
      for (i=0; i < `MSG_BLKCNT; i=i+1) begin : M_ARR
	 assign Min_arr[i] = M[(`MSG_BLKCNT - i)*32 - 1 : (`MSG_BLKCNT - i - 1)*32];
      end
   endgenerate

   generate
      for (i=0; i < `W_BLKCNT; i=i+1) begin : W_ARR
	 assign  W_arr[i] = W[(i+1)*32 - 1:i*32];
      end
   endgenerate

   always @(posedge clk)
     begin
	en_next <= 0;

	
	if (cnt != 6'h0 || (cnt == 6'h0 && en != 0)) begin
	   if (cnt < 6'h10)
	     W[cnt*32 +: `WORD_S] <= Min_arr[cnt];
	   else
	     W[cnt*32 +: `WORD_S] <= `sig1(W_arr[cnt - 2]) + W_arr[cnt - 7] + `sig0(W_arr[cnt - 15]) + W_arr[cnt - 16];
	   if (cnt == 6'h3F) begin
	      en_next <= 1;
	      cnt <= 6'h0;
	   end
	   else
	     cnt = cnt + 6'h1;
	end
     end
endmodule // sha_w
