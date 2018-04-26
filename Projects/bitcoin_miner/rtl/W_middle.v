`include "sha.vh"

module W_middle (
	     input 		      clk,
	     input 		      reset,
	     input 		      en,
	     input 	[`WARR_S-1:0]      Win,

	     output reg [`WARR_S-1:0] W,
	     output reg 	      en_next
	     );

   wire [`WORD_S-1:0] 		      W_arr[`W_BLKCNT*2-1:0];

   reg [4:0] 			      cnt = 5'h0;

   genvar 			      i;

   generate
      for (i=0; i < `W_BLKCNT; i=i+1) begin : WIN_ARR
	 assign  W_arr[i] = Win[(i+1)*32 - 1:i*32];
      end
   endgenerate

   generate
      for (i=`DELAY; i < `W_BLKCNT*2; i=i+1) begin : W_ARR
	 assign  W_arr[i] = W[(i - `DELAY +1)*32 - 1:(i - `DELAY)*32];
      end
   endgenerate

   always @(posedge clk)
     begin
	en_next <= 0;

	if (reset == 1) begin
		en_next <= 0;
		W <= {`WARR_S{1'b0}};
	end else if (cnt != 5'h0 || (cnt == 5'h0 && en != 0)) begin
	     W[cnt*32 +: `WORD_S] <= `sig1(W_arr[`DELAY + cnt - 2]) + W_arr[`DELAY + cnt - 7] + `sig0(W_arr[`DELAY + cnt - 15]) + W_arr[`DELAY + cnt - 16];

	   if (cnt == (`DELAY - 1)) begin
	      en_next <= 1;
	      cnt <= 5'h0;
	   end
	   else
	     cnt <= cnt + 5'h1;
	end
     end
endmodule // sha_w
