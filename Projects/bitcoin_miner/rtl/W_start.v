`include "sha.vh"

module W_start (
		input 			 clk,
		input 			 reset,
		input 			 en,

		input [`WORD_S-1:0] 	 nonce,
		input [`MSG_S-1:0] 	 M,
		input [`H_SIZE-1:0] 	 Hin,

		output reg [`WORD_S-1:0] nonce_out,
		output reg [`WARR_S-1:0] W,
		output reg [`H_SIZE-1:0] H,
		output reg 		 en_next
		);

   wire [`WORD_S-1:0] 			 Min_arr[`MSG_BLKCNT - 1:0];
   wire [`WORD_S-1:0] 			 W_arr[`W_BLKCNT-1:0];

   reg [4:0] 				 cnt = 5'h0;

   genvar 				 i;

   generate
      for (i=0; i < `MSG_BLKCNT; i=i+1) begin : M_ARR
	 assign Min_arr[i] = M[(`MSG_BLKCNT - i)*`WORD_S - 1 : (`MSG_BLKCNT - i - 1)*`WORD_S];
      end
   endgenerate

   generate
      for (i=0; i < `W_BLKCNT; i=i+1) begin : W_ARR
	 assign  W_arr[i] = W[i*32 +: `W_SIZE];
      end
   endgenerate

   generate
      for (i=0; i < `W_BLKCNT; i=i+1) begin
	 always @(posedge clk)
	   begin
	      if (en == 1'b1)
		W[i*32 +: `WORD_S] <= Min_arr[i];
	   end
      end
   endgenerate
   
   always @(posedge clk)
     begin
	en_next <= 1'b0;
	
	if (reset == 1'b1) begin
	   en_next <= 1'b0;
	   H <= {`H_SIZE{1'b0}};
	   nonce_out <= {`WORD_S{1'b0}};
	end
	else if (en == 1'b1) begin
	   H <= Hin;
	   nonce_out <= nonce;
	   en_next <= 1'b1;
	end
     end
endmodule
