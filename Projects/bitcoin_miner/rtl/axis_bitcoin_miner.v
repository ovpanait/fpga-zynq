`include "sha.vh"

module axis_bitcoin_miner #
  (
   parameter NUMBER_OF_INPUT_WORDS = 20,
   parameter NUMBER_OF_OUTPUT_WORDS = 8,
   parameter AXIS_TDATA_WIDTH = 32   
   )
   (
    input 						   clk,
    input 						   reset,
    input 						   en,
    input [(NUMBER_OF_INPUT_WORDS*AXIS_TDATA_WIDTH)-1:0]   in_fifo,
    
    output [(NUMBER_OF_OUTPUT_WORDS*AXIS_TDATA_WIDTH)-1:0] out_fifo,
    output reg 						   done
    );

   wire [AXIS_TDATA_WIDTH-1:0] 				   in_stream_data_fifo [0 : NUMBER_OF_INPUT_WORDS - 1];
   wire [AXIS_TDATA_WIDTH-1:0] 				   out_stream_data_fifo [0 : NUMBER_OF_OUTPUT_WORDS - 1];

   genvar 						   j;
   generate for (j = 0; j < NUMBER_OF_INPUT_WORDS; j=j+1) begin
      assign in_stream_data_fifo[j] =  in_fifo[j*32 +: 32];
   end
   endgenerate

   generate for (j = 0; j < NUMBER_OF_OUTPUT_WORDS; j=j+1) begin
      assign  out_fifo[j*32 +: 32] = out_stream_data_fifo[j];
   end
   endgenerate   
   
   /* Bitcoin miner logic */
   wire [`VERSION_S-1:0] 				   blk_version;
   wire [`H_SIZE-1:0] 					   prev_blk_header_hash;
   wire [`H_SIZE-1:0] 					   merkle_root_hash;
   wire [`TIME_S-1:0] 					   blk_time;
   wire [`NBITS_S-1:0] 					   blk_nbits;
   wire [`WORD_S-1:0] 					   blk_nonce;
   

   wire [`H_SIZE-1:0] 					   bitcoin_blk;
   wire [`WORD_S-1:0] 					   bitcoin_nonce;
   wire 						   bitcoin_done;
   
   // Map in_stream_data_fifo to bitcoin_block inputs
   assign blk_version = in_stream_data_fifo[0];
   assign prev_blk_header_hash = {
				  in_stream_data_fifo[1],
				  in_stream_data_fifo[2],
				  in_stream_data_fifo[3],
				  in_stream_data_fifo[4],
				  in_stream_data_fifo[5],
				  in_stream_data_fifo[6],
				  in_stream_data_fifo[7],
				  in_stream_data_fifo[8]
				  };
   assign merkle_root_hash = {
			      in_stream_data_fifo[9],
			      in_stream_data_fifo[10],
			      in_stream_data_fifo[11],
			      in_stream_data_fifo[12],
			      in_stream_data_fifo[13],
			      in_stream_data_fifo[14],
			      in_stream_data_fifo[15],
			      in_stream_data_fifo[16]
			      };
   assign blk_time = in_stream_data_fifo[17];
   assign blk_nbits = in_stream_data_fifo[18];
   assign blk_nonce = in_stream_data_fifo[19];
   
   // Map out_stream_data_fifo to bitcoin_block outputs
   generate for (j = 0; j < 8; j=j+1) begin
      assign out_stream_data_fifo[8 - 1 - j] =  bitcoin_blk[j*32 +: 32];
   end
   endgenerate
   
   bitcoin_block miner(
		       .clk(clk),
		       .reset(reset),
		       .start(en),

    		       .blk_version(blk_version),
		       .prev_blk_header_hash(prev_blk_header_hash),
		       .merkle_root_hash(merkle_root_hash),
		       .blk_time(blk_time),
		       .blk_nbits(blk_nbits),
		       .blk_nonce(blk_nonce),

		       .bitcoin_blk(bitcoin_blk),
		       .bitcoin_nonce(bitcoin_nonce),
		       .bitcoin_done(bitcoin_done)
		       );

   always @(posedge clk)
     begin
	done <= bitcoin_done;
     end
endmodule // axis_bitcoin_miner





