`include "sha.vh"

module W_start (
		input 			 clk,
		input 			 reset,
		input 			 en,

		input [`WORD_S-1:0] 	 nonce,
		input [`WARR_S-1:0] 	 W_in,
		input [`H_SIZE-1:0] 	 Hin,

		output reg [`WORD_S-1:0] nonce_out,
		output reg [`WARR_S-1:0] W,
		output reg [`H_SIZE-1:0] H,
		output reg 		 en_next
		);

   reg [4:0] 				 cnt = 5'h0;

   always @(posedge clk)
     begin
	en_next <= 1'b0;
	
	if (reset == 1'b1) begin
	   en_next <= 1'b0;
	   H <= {`H_SIZE{1'b0}};
	   nonce_out <= {`WORD_S{1'b0}};
	end
	else begin
	   if ((en == 1'b1) || (en == 1'b0 && cnt != 5'b0)) begin
	      cnt <= cnt + 1'b1;
	   end
	   
	   if (cnt == (`DELAY-1))
	     begin
		W <= W_in;
		H <= Hin;
		nonce_out <= nonce;
		en_next <= 1'b1;
	     end
	end
     end
endmodule
