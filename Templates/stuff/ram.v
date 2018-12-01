/* 
 Minimal example for inferring BRAM.
 https://www.xilinx.com/support/documentation/sw_manuals/xilinx14_7/xst_v6s6.pdf
 page 285
*/

module ram (a, clk, din, spo);
	parameter ADDRESSWIDTH = 10;
	parameter BITWIDTH = 32;
	parameter DEPTH = 1024;
		
	input clk, din;
	input [ADDRESSWIDTH-1:0] a;
	
	output spo;
	
	(* ram_style = "block" *)
	reg [BITWIDTH-1:0] ram [DEPTH-1:0];
	reg [ADDRESSWIDTH-1:0] read_a; 

	always @(posedge clk) begin
		ram [a] <= din;
		read_a <= a;
	end
	
	assign spo = ram [read_a];
endmodule
