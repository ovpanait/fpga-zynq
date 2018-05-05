`include "sha.vh"

`define WAITING 8'hA0
`define WORKING 8'hA1
`define MSG_START 8'hA2
`define GET_STATE 8'hA3
`define GET_MSG 8'hA4
`define DONE 8'hA5
`define DONE_FOUND 8'h6

module miner_top(
	input clk,
	input reset,

	input sck,
	input mosi,
	input ssel,
	output miso
	);

  wire byte_received;
  wire[7:0] received_data;
  wire data_needed;
  reg[7:0] data_to_send;
  reg[7:0] received_data_buffer;

  reg receiving_data;
  reg sending_data;
  reg [7:0] byte_cnt;

  reg [`H_SIZE-1:0] first_stage_hash;
  reg [`H_SIZE-1:0] prev_blk;
  reg [`INPUT_S-1:0] input_M;

  wire [`WORD_S-1:0] nonce;
  wire [`H_SIZE-1:0] winner_H;
  wire sha_done, sha_found;

  reg [`WORD_S-1:0] res_nonce;
  reg [`H_SIZE-1:0] res_hash;
  reg sha_en;

  SPI_slave spi_slave(clk, sck, mosi, miso, ssel, byte_received, received_data, data_needed, data_to_send);

  sha_top SHA(
		.clk(clk),
		.reset(reset),
		.en(sha_en),

		 .prev_blk(prev_blk),
		 .prev_H(first_stage_hash),
		 .input_M(input_M),

		.nonce(nonce),
		.winner_H(winner_H),
		.found(sha_found),
		.done(sha_done)
		);

  always @(posedge clk) begin
	sha_en <= 0;
	if (reset) begin
		data_to_send <= `WAITING;
		byte_cnt <= 7'h0;
		receiving_data <= 0;
		sending_data <= 0;
		first_stage_hash <= {256{1'b0}};
		input_M <= {96{1'b0}};
	end else if (byte_received) begin
		if (receiving_data) begin
			byte_cnt <= byte_cnt + 7'h1;

			if (byte_cnt < 32) // first stage hash
				first_stage_hash <= {first_stage_hash[255-8:0], received_data};
			else if (byte_cnt < 44) // input message
				input_M <= {input_M[95-8:0], received_data};
			else // previous block
				prev_blk <= {prev_blk[255-8:0], received_data};

			if (byte_cnt == 75) begin // end of data input -- start of pipeline processing
				byte_cnt <= 7'h0;
				receiving_data <= 0;
				data_to_send <= `WORKING;
				sha_en <= 1;
			end
		end else if (sending_data) begin
			byte_cnt <= byte_cnt + 7'h1;

			if (byte_cnt < 32) begin // first stage hash
				data_to_send <= first_stage_hash[255:255-7];
				first_stage_hash <= {first_stage_hash[255-8:0], 8'h0};
			end else if(byte_cnt < 44) begin // input message
				data_to_send <= input_M[95:95-7];
				input_M <= {input_M[95-8:0], 8'h0};
			end else begin // previous block
				data_to_send <= prev_blk[255:255-7];
				first_stage_hash <= {prev_blk[255-8:0], 8'h0};
			end

			if (byte_cnt == 75) begin
				byte_cnt <= 5'h0;
				sending_data <= 0;
				data_to_send <= `WAITING;
			end
		end else
			case (received_data)
				`MSG_START: begin
					byte_cnt <= 7'h0;
					receiving_data <= 1;
				end
				`GET_MSG: begin
					byte_cnt <= 7'h0;
					sending_data <= 1;
				end
			endcase
	end

	if (sha_done) begin
		data_to_send <= `DONE;
		if (sha_found) begin
			res_nonce <= nonce;
			res_hash <= winner_H;
			data_to_send <= `DONE_FOUND;
		end

	end


  end
endmodule
