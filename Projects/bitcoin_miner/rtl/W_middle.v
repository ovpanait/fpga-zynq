`include "sha.vh"

module W_middle (
		 input 		      clk,
		 input 		      reset,
		 input 		      en,
		 input [`WARR_S-1:0]  Win,

		 output [`WARR_S-1:0] W
		 );

   wire [`WORD_S-1:0] 		      W_arr[`W_BLKCNT + `DELAY -1:0];
   reg [`WORD_S-1:0] 		      W_buf[`DELAY-1:0];

   reg [8:0] 			      cnt = 5'h0;

   genvar 			      i;
   
   generate
      for (i=0; i < `W_BLKCNT; i=i+1) begin
	 assign W_arr[i] = Win[i*`WORD_S +: `WORD_S];
      end
   endgenerate
   
   generate
      for (i=0; i < `DELAY; i=i+1) begin : W_ARR
	 assign  W_arr[`W_BLKCNT + i] = W_buf[i];
      end
   endgenerate

   generate
      for (i=0; i < `W_BLKCNT; i=i+1) begin : W_out
	 assign  W[i*`WORD_S +: `WORD_S] = W_arr[`DELAY + i];
      end
   endgenerate
   
   always @(posedge clk)
     begin
	if (cnt != 5'h0 || (cnt == 5'h0 && en != 0)) begin
	   W_buf[cnt] <= `sig1(W_arr[`W_BLKCNT + cnt - 2]) + W_arr[`W_BLKCNT + cnt - 7] + `sig0(W_arr[`W_BLKCNT + cnt - 15]) + W_arr[`W_BLKCNT + cnt - 16];

	   if (cnt == (`DELAY - 1)) begin
	      cnt <= 5'h0;
	   end
	   else
	     cnt <= cnt + 5'h1;
	end
     end
endmodule
