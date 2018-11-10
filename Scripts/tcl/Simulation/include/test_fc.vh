// Test setup
integer     errors;

class tester #(
	       int unsigned WIDTH = 32,
	       int unsigned UNPACKED_WIDTH = 8);
   static task verify_output(input [WIDTH-1:0] simulated_value, input [WIDTH-1:0] expected_value);
      begin
	 if (simulated_value[WIDTH-1:0] != expected_value[WIDTH-1:0])
	   begin
	      errors = errors + 1;
	      $display("Simulated Value = %h \n Expected Value = %h \n errors = %d \n at time = %d",
		       simulated_value,
		       expected_value,
		       errors,
		       $time);
	   end
      end
   endtask

   static task packed_to_unpacked(input [WIDTH-1:0] data_in, output [UNPACKED_WIDTH-1:0] data_unpacked []);
      begin
	 data_unpacked.delete();
	 data_unpacked = new [WIDTH/UNPACKED_WIDTH];
	 
	 for (int i = 0; i < WIDTH/UNPACKED_WIDTH; ++i)
	   data_unpacked[i] = data_in[WIDTH - (i + 1)*UNPACKED_WIDTH +: UNPACKED_WIDTH];
      end
   endtask

   // big endian format
   static task print_unpacked(input [UNPACKED_WIDTH-1:0] data_unpacked[]);
      begin
	 $write("0x");
	 for(int i = 0; i < $size(data_unpacked); i++) begin
	    $write("%H", data_unpacked[i]);
	 end
	 $display("");
      end
   endtask
endclass
