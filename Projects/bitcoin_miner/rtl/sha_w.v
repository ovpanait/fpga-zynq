`include "sha.vh"

module sha_w(
	     input 		     clk,
	     input 		     reset,
	     input 		     en,
	     input [`W_MAX : 0]      M[31:0],
	     
	     output reg [`W_MAX : 0] W[31:0],
	     output reg 	     en_next
	     );

   reg [`W_MAX:0] 		     W_regs[31:0];
   reg [4:0] 			     cnt;
	 
always @(posedge clk)
  begin
     en_next <= 0;

     if (cnt == 5'h1F) begin
	en_next <= 1;
	W <= W_regs;
	cnt <= 5'h0;
     end
     else if (cnt != 5'h0 || (cnt == 5'h0 && en != 0)) begin
	if (cnt < 5'h10)
	  W_regs[cnt] <= M[cnt];
	else
	  W_regs[cnt] <= `sig1(W_regs[cnt - 2]) + W_regs[cnt - 7] + `sig0(W_regs[cnt - 15]) + W_regs[cnt - 16];
     end
  end
endmodule // sha_w
