
`timescale 1 ns / 1 ps

module myip_v1_0_S00_AXIS #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line

   // AXI4Stream sink: Data Width
   parameter integer C_S_AXIS_TDATA_WIDTH = 32
   )
   (
    // Users to add ports here
    output reg [3:0] 				led,
    // User ports ends
   
    // Do not modify the ports beyond this line

    // AXI4Stream sink: Clock
    input wire 					S_AXIS_ACLK,
    // AXI4Stream sink: Reset
    input wire 					S_AXIS_ARESETN,
    // Ready to accept data in
    output wire 				S_AXIS_TREADY,
    // Data in
    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] 	S_AXIS_TDATA,
    // Byte qualifier
    input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
    // Indicates boundary of last packet
    input wire 					S_AXIS_TLAST,
    // Data is in valid
    input wire 					S_AXIS_TVALID
    );
   // function called clogb2 that returns an integer which has the 
   // value of the ceiling of the log base 2.
   function integer clogb2 (input integer bit_depth);
      begin
	 for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	   bit_depth = bit_depth >> 1;
      end
   endfunction

   // Total number of input data.
   localparam NUMBER_OF_INPUT_WORDS  = 8;
   // bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
   localparam bit_num  = clogb2(NUMBER_OF_INPUT_WORDS-1);
   // Define the states of state machine
   // The control state machine oversees the writing of input streaming data to the FIFO,
   // and outputs the streaming data from the FIFO
   parameter [1:0] IDLE = 1'b0,        // This is the initial/idle state 

     WRITE_FIFO  = 1'b1, // In this state FIFO is written with the
     // input stream data S_AXIS_TDATA
 
     PROCESS_STUFF = 2'b11; // In this state data is being processed
   
   wire  	axis_tready;
   // State variable
   reg [1:0] 	mst_exec_state;  
   // FIFO implementation signals
   genvar 	byte_index;     
   // FIFO write enable
   wire 	fifo_wren;
   // FIFO full flag
   reg 		fifo_full_flag;
   // FIFO write pointer
   reg [bit_num-1:0] write_pointer;
   // sink has accepted all the streaming data and stored in FIFO
   reg 		     writes_done;
   // I/O Connections assignments

   assign S_AXIS_TREADY	= axis_tready;
   // Control state machine implementation
   always @(posedge S_AXIS_ACLK) 
     begin  
	if (!S_AXIS_ARESETN) 
	  // Synchronous reset (active low)
	  begin
	     mst_exec_state <= IDLE;
	  end  
	else
	  case (mst_exec_state)
	    IDLE: 
	      // The sink starts accepting tdata when 
	      // there tvalid is asserted to mark the
	      // presence of valid streaming data 
	      if (S_AXIS_TVALID)
	        begin
	           mst_exec_state <= WRITE_FIFO;
	        end
	      else
	        begin
	           mst_exec_state <= IDLE;
	        end
	    WRITE_FIFO: 
	      // When the sink has accepted all the streaming input data,
	      // the interface swiches functionality to a streaming master
	      if (writes_done)
	        begin
	           mst_exec_state <= PROCESS_STUFF;
	        end
	      else
	        begin
	           // The sink accepts and stores tdata 
	           // into FIFO
	           mst_exec_state <= WRITE_FIFO;
	        end
            PROCESS_STUFF:
              if (processing_done)
		begin
                   mst_exec_state <= IDLE;
		end
              else
		begin
                   mst_exec_state <= PROCESS_STUFF;
		end
	  endcase
     end
   // AXI Streaming Sink 
   // 
   // The example design sink is always ready to accept the S_AXIS_TDATA  until
   // the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
   assign axis_tready = ((mst_exec_state == WRITE_FIFO) && !writes_done);

   always@(posedge S_AXIS_ACLK)
     begin
	if(!S_AXIS_ARESETN)
	  begin
	     write_pointer <= 0;
	     writes_done <= 1'b0;
	  end  
	else
	  begin
	     if (fifo_wren)
	       begin
	          if ((write_pointer == NUMBER_OF_INPUT_WORDS-1) || S_AXIS_TLAST)
	            begin
	               // reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
	               // has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	               writes_done <= 1'b1;
	            end
	          else begin
                     write_pointer <= write_pointer + 1;
	          end
	       end
	     
	     if (processing_done)
	       begin
	          write_pointer <= 1'b0;
	          writes_done <= 1'b0;
	       end
	  end
     end

   // FIFO write enable generation
   assign fifo_wren = S_AXIS_TVALID && axis_tready;

   // FIFO Implementation
   
   reg  [C_S_AXIS_TDATA_WIDTH-1:0] stream_data_fifo [0 : NUMBER_OF_INPUT_WORDS-1];        
   // Streaming input data is stored in FIFO

   always @( posedge S_AXIS_ACLK )
     begin
	if (fifo_wren)// && S_AXIS_TSTRB[byte_index])
          begin
             stream_data_fifo[write_pointer] <= S_AXIS_TDATA;
          end  
     end

   wire not_equal;
   reg 	reads_done;
   reg 	processing_done;
   wire start_processing;

   assign start_processing = (mst_exec_state == PROCESS_STUFF) && !processing_done;

   assign not_equal =  (stream_data_fifo[0] ^
                        stream_data_fifo[1] ^
                        stream_data_fifo[2] ^
                        stream_data_fifo[3] ^
                        stream_data_fifo[4] ^
                        stream_data_fifo[5] ^
                        stream_data_fifo[6] ^
                        stream_data_fifo[7]) ? 1 :0; // hardcode this shit

   // Processing routine
   always @(posedge S_AXIS_ACLK)
     begin
        processing_done <= 1'b0;

        if (start_processing)
          begin
             if (not_equal)
               led <= 4'b0011;
             else 
               led <= 4'b1100;
             
             processing_done <= 1'b1;
          end  
     end

endmodule