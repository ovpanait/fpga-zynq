`include "sha.vh"

module bitcoin_miner_top #
  (
   /*
    * Master side parameters
    */
   // Width of master side bus
   parameter integer C_M_AXIS_TDATA_WIDTH = 32,
   // Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
   parameter integer C_M_START_COUNT = 32,

   /*
    * Slave side parameters
    */
   // Width of slave side bus
   parameter integer C_S_AXIS_TDATA_WIDTH = 32
   )
   (
    /*
     * Master side ports
     */

    input wire 					 m00_axis_aclk,
    input wire 					 m00_axis_aresetn,
    output wire 				 m00_axis_tvalid,
    output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] 	 m00_axis_tdata,
    output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
    output wire 				 m00_axis_tlast,
    input wire 					 m00_axis_tready,

    /*
     * Slave side ports
     */

    input wire 					 s00_axis_aclk,
    input wire 					 s00_axis_aresetn,
    output wire 				 s00_axis_tready,
    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] 	 s00_axis_tdata,
    input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0]  s00_axis_tstrb,
    input wire 					 s00_axis_tlast,
    input wire 					 s00_axis_tvalid
    );

   // function called clogb2 that returns an integer which has the
   // value of the ceiling of the log base 2.
   function integer clogb2 (input integer bit_depth);
      begin
	 for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	   bit_depth = bit_depth >> 1;
      end
   endfunction

   // Input FIFO size (slave side)
   localparam NUMBER_OF_INPUT_WORDS  = 20;
   // Output FIFO size (master side)
   localparam NUMBER_OF_OUTPUT_WORDS = 8;

   // bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
   localparam bit_num  = clogb2(NUMBER_OF_INPUT_WORDS-1);

   // Control state machine states
   parameter [1:0] IDLE = 1'b0, // Initial/idle state

     WRITE_FIFO  = 1'b1, // Input FIFO is written with the input stream data S_AXIS_TDATA

     PROCESS_STUFF = 2'b11, // Data is being processed and placed into the output FIFO

     MASTER_SEND = 2'b10; // Master is sending processed data

   // =====================================================================

   /*
    * Master side signals
    */
   reg [bit_num-1:0] read_pointer;

   // AXI Stream internal signals
   wire 	     axis_tvalid;
   wire 	     axis_tlast;

   reg 		     axis_tvalid_delay;
   reg 		     axis_tlast_delay;
   
   wire [C_M_AXIS_TDATA_WIDTH-1 : 0] out_stream_data_fifo [0 : NUMBER_OF_OUTPUT_WORDS - 1];
   wire 			    tx_en;

   reg 				    tx_done;

   /*
    * Slave side signals
    */
   wire 			    axis_tready;
   reg [1:0] 			    mst_exec_state;
   genvar 			    byte_index;
   wire 			    fifo_wren;
   reg [bit_num-1:0] 		    write_pointer;
   reg 				    writes_done;

   wire 				    processing_done;
   wire 			    start_processing;

   // Control state machine implementation
   always @(posedge s00_axis_aclk)
     begin
	if (!s00_axis_aresetn)
	  // Synchronous reset (active low)
	  begin
	     mst_exec_state <= IDLE;
	  end
	else
	  case (mst_exec_state)
	    IDLE:
	      if (s00_axis_tvalid)
	        begin
	           mst_exec_state <= WRITE_FIFO;
	        end
	      else
	        begin
	           mst_exec_state <= IDLE;
	        end
	    WRITE_FIFO:
	      if (writes_done)
	        begin
	           mst_exec_state <= PROCESS_STUFF;
	        end
	      else
	        begin
	           mst_exec_state <= WRITE_FIFO;
	        end
            PROCESS_STUFF:
              if (processing_done)
		begin
                   mst_exec_state <= MASTER_SEND;
		end
              else
		begin
                   mst_exec_state <= PROCESS_STUFF;
		end
	    MASTER_SEND:
	      if (tx_done)
	        begin
	           mst_exec_state <= IDLE;
	        end
	      else
	        begin
	           mst_exec_state <= MASTER_SEND;
	        end
	  endcase
     end

   // =====================================================================

   /*
    * Master side logic
    */

   /*
    * Master side I/O Connections assignments
    */
   assign m00_axis_tvalid	= axis_tvalid;
   assign m00_axis_tdata	= out_stream_data_fifo[read_pointer];
   assign m00_axis_tlast	= axis_tlast;
   assign m00_axis_tstrb	= {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};

   assign axis_tlast = (read_pointer == NUMBER_OF_OUTPUT_WORDS-1);
   assign axis_tvalid = (mst_exec_state == MASTER_SEND) && !tx_done;
   assign tx_en = m00_axis_tready && axis_tvalid;

   always @(posedge m00_axis_aclk)
     begin
	if(!m00_axis_aresetn)
	  begin
	     read_pointer <= 0;
	     tx_done <= 1'b0;
	  end
	else begin
	   tx_done <= 1'b0;
	   
	   if (tx_en)
             begin
		if (read_pointer == NUMBER_OF_OUTPUT_WORDS-1)
		  begin
		     read_pointer <= 1'b0;
		     tx_done <= 1'b1;
		  end
		else
		  begin
		     read_pointer <= read_pointer + 1'b1;
		     tx_done <= 1'b0;
		  end
	     end // if (tx_en)
	end
     end

 
  // =====================================================================

   /*
    * Slave side logic
    */

   /*
    * Slave side I/O Connections assignments
    */
   assign s00_axis_tready	= axis_tready;
   
   assign axis_tready = ((mst_exec_state == WRITE_FIFO) && !writes_done);

   always@(posedge s00_axis_aclk)
     begin
	if(!s00_axis_aresetn)
	  begin
	     write_pointer <= 1'b0;
	     writes_done <= 1'b0;
	  end
	else
	  begin
	     if (fifo_wren)
	       begin
	          if ((write_pointer == NUMBER_OF_INPUT_WORDS-1) || s00_axis_tlast)
	            begin
	               writes_done <= 1'b1;
	            end
	          else begin
                     write_pointer <= write_pointer + 1'b1;
	          end
	       end

	     if (processing_done)
	       begin
	          write_pointer <= 1'b0;
	          writes_done <= 1'b0;
	       end
	  end
     end

   assign fifo_wren = s00_axis_tvalid && axis_tready;

   reg  [C_S_AXIS_TDATA_WIDTH-1:0] in_stream_data_fifo [0 : NUMBER_OF_INPUT_WORDS-1];

   always @(posedge s00_axis_aclk)
     begin
	if (fifo_wren)// && S_AXIS_TSTRB[byte_index])
          begin
             in_stream_data_fifo[write_pointer] <= s00_axis_tdata;
          end
     end

   assign start_processing = (mst_exec_state == PROCESS_STUFF) && !processing_done;


   wire [(NUMBER_OF_INPUT_WORDS*C_S_AXIS_TDATA_WIDTH)-1:0]   in_fifo; 
   wire [(NUMBER_OF_OUTPUT_WORDS*C_S_AXIS_TDATA_WIDTH)-1:0] out_fifo;
   
   // Map in_stream_data_fifo to in_fifo
   genvar 						   j;
   generate for (j = 0; j < NUMBER_OF_INPUT_WORDS; j=j+1) begin
      assign in_fifo[j*C_S_AXIS_TDATA_WIDTH +: C_S_AXIS_TDATA_WIDTH] = in_stream_data_fifo[j];
   end
   endgenerate

   // Map out_stream_data_fifo to out_fifo
   generate for (j = 0; j < NUMBER_OF_OUTPUT_WORDS; j=j+1) begin
      assign out_stream_data_fifo[j] = out_fifo[j*C_S_AXIS_TDATA_WIDTH +: C_S_AXIS_TDATA_WIDTH];
   end
   endgenerate
 
   axis_bitcoin_miner test_miner(
			    .clk(s00_axis_aclk),
			    .reset(!s00_axis_aresetn),
			    .en(start_processing),

			    .in_fifo(in_fifo),
			    .out_fifo(out_fifo),
			    .done(processing_done)
			    );
   			    
endmodule
