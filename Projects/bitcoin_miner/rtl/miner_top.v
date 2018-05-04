`define WAITING 8'hA0
`define WORKING 8'hA1

`define MSG_START 8'hA2

`define GET_STATE 8'hA3
`define GET_MSG 8'hA4

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
  reg [255:0] H_prev;
  reg [95:0] input_M;
  
  reg spi_clk;
  
  SPI_slave spi_slave(clk, sck, mosi, miso, ssel, byte_received, received_data, data_needed, data_to_send);

  always @(posedge clk) begin
	if (reset) begin
		data_to_send <= `WAITING;
		byte_cnt <= 7'h0;
		receiving_data <= 0;
		sending_data <= 0;
		H_prev <= {256{1'b0}};
		input_M <= {96{1'b0}};
	end else if (byte_received) begin
		if (receiving_data) begin
			byte_cnt <= byte_cnt + 7'h1;
			
			if (byte_cnt < 32) // end of H_prev
				H_prev <= {H_prev[255-8:0], received_data};
			else
				input_M <= {input_M[95-8:0], received_data};
				
			if (byte_cnt == 43) begin // end of data input
				byte_cnt <= 7'h0;
				receiving_data <= 0;
				data_to_send <= `WAITING;
			end
		end else if (sending_data) begin
			byte_cnt <= byte_cnt + 7'h1;
			
			if (byte_cnt < 32) begin
				data_to_send <= H_prev[255:255-7];
				H_prev <= {H_prev[255-8:0], 8'h0};
			end else begin
				data_to_send <= input_M[95:95-7];
				input_M <= {input_M[95-8:0], 8'h0};
			end
			
			if (byte_cnt == 44) begin
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
  end
endmodule
