`define WAITING 8'hA0

module SPI_driver(
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

  reg need_send;
  reg [7:0] answer;

  SPI_slave spi_slave(clk, sck, mosi, miso, ssel, byte_received, received_data, data_needed, data_to_send);

  always @(posedge clk) begin
	if (byte_received && received_data == 8'hF0) begin
		need_send <= 1;
		answer <= `WAITING;
	end else if (need_send && data_needed) begin
		need_send <= 0;
		data_to_send <= answer;
	end
  end


endmodule
