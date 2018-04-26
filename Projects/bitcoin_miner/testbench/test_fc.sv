// Test setup
integer     errors;

class tester #(int unsigned WIDTH = 32);
   static task verify_output(input [WIDTH-1:0] simulated_value, input [WIDTH-1:0] expected_value);
      begin
	 if (simulated_value[WIDTH-1:0] != expected_value[WIDTH-1:0])
	   begin
	      errors = errors + 1;
	      $display("Simulated Value = %h \n Expected Value = %h \n errors = %d \n at time = %d\n",
			simulated_value,
			expected_value,
			errors,
			$time);
	   end
	end
	endtask
endclass
