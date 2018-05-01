`include "sha.vh"

module W_start (
	     input 		      clk,
	     input 		      reset,
	     input 		      en,

	     input [`WORD_S-1:0]      nonce,
	     input [`MSG_S-1:0]       M,
	     input [`H_SIZE-1:0]      Hin,

	     output reg [`WORD_S-1:0] nonce_out,
	     output reg [`WARR_S-1:0] W,
	     output reg [`H_SIZE-1:0] H,
	     output reg 	      en_next
	     );

   wire [`WORD_S-1:0] 		      Min_arr[`MSG_BLKCNT - 1:0];
   wire [`WORD_S-1:0] 		      W_arr[`W_BLKCNT-1:0];

   reg [4:0] 			      cnt = 5'h0;

   genvar 			      i;

   generate
      for (i=0; i < `MSG_BLKCNT; i=i+1) begin : M_ARR
	 assign Min_arr[i] = M[(`MSG_BLKCNT - i)*`WORD_S - 1 : (`MSG_BLKCNT - i - 1)*`WORD_S];
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

	if (reset == 1) begin
		en_next <= 0;
		W <= {`WARR_S{1'b0}};
		H <= {`H_SIZE{1'b0}};
		nonce_out <= {`WORD_S{1'b0}};
	end else if (cnt != 5'h0 || (cnt == 5'h0 && en != 0)) begin
	   // Save previous hash buffer
	   if (en == 1) begin
		H <= Hin;
		nonce_out <= nonce;
	   end

	   // Processing
	   if (cnt < 5'h10)
	     W[cnt*32 +: `WORD_S] <= Min_arr[cnt];
	   else
	     W[cnt*32 +: `WORD_S] <= `sig1(W_arr[cnt - 2]) + W_arr[cnt - 7] + `sig0(W_arr[cnt - 15]) + W_arr[cnt - 16];

	   if (cnt == `DELAY - 1) begin
	      en_next <= 1;
	      cnt <= 5'h0;
	   end
	   else
	     cnt <= cnt + 5'h1;
	end
     end
endmodule // sha_w
