/*
* Accelerator module (generic template).
* Fits both types - MMIO and RoCC accelerators.
* Counts latency.
*/

`define RoCC_NUM_INPUTS 97
`define RoCC_NUM_OUTPUTS 48 // 49 with funct input, it is a special one so I treated it differently
// the number of registers to be configured: RoCC_NUM_INPUTS + (RoCC_NUM_OUTPUTS + 1 /*+1 is funct*/) + NUM_OF_CFG_REGS (Rocc)


module MMIOAccBlackBox#
(
// Define module parameters (the accelerator's traits)
  parameter int address = 64'h1000,
  parameter int DATA_WIDTH 	   = 8,    // Data width in bits.
  parameter int ADDR_WIDTH 	   = 10,   // Address width in bits.
  parameter int CFG_REG_WIDTH    = 32,   // number of register bits.
  parameter int NUM_OF_CFG_REGS  = 3,    // depends on many variables?
  parameter int MEM_DATA_WIDTH   = 8,    // number of bits used to transfer data between a MMIO accelerator and the system memory. This parameter defines the size of the data bus used for memory transactions.
  parameter int TOT_CFG_REGS = 149, 
  parameter int BUFF_SIZE	   	= 32,   // Buffer size in bytes. helps our memory access.
  parameter int LATENCY   	   	= 500,  // later, this should be per instruction - opcode. Latency is the time required for the accelerator to complete a single operation.
  parameter int MEMORY_BANDWIDTH = 300   // measured in bps (bytes per second), this should be a unique accelerator trait. affects performance.
//parameter int pipeline
)
(
//define the inputs/outputs
	input 	  	       clock,
	input 	  	       reset,

	output    	       input_ready,
    	input     	       input_valid,
    	input                  output_ready,
    	output                 output_valid,
    	output                 busy,

    	output reg [31:0] data_out,
//	input [NUM_OF_CFG_REGS  - 1 : 0] [CFG_REG_WIDTH - 1 : 0]  common_cfg_regs_,
//	input [RoCC_NUM_INPUTS  - 1 : 0] [CFG_REG_WIDTH - 1 : 0]  input_cfg_regs_,
//	input [RoCC_NUM_OUTPUTS - 1 : 0] [CFG_REG_WIDTH - 1 : 0]  output_cfg_regs,
	input [CFG_REG_WIDTH    - 1 : 0]   funct_cfg_reg
	//need to map all in reg map
);

reg [31:0] io_resp_data_reg;
reg io_resp_valid_reg;
reg io_busy_reg;
reg io_cmd_ready_reg;
reg [CFG_REG_WIDTH-1:0] io_cmd_bits_inst_funct;
reg io_cmd_valid;


// define the registers array.
logic [CFG_REG_WIDTH - 1 : 0] reg_array [NUM_OF_CFG_REGS - 1 : 0];   

int counter;
int target_latency;
logic flag;
logic flag2;

genvar i;

generate
	for (i = 0; i < NUM_OF_CFG_REGS; i++) begin : init_loop
      initial reg_array[i] = 0;
	end
endgenerate
  

always_ff@(posedge clock, negedge reset) begin

	if(reset) begin
		counter 	     	      <= 0;
		flag                 	      <= 0;
		flag2			      <= 0;
		io_resp_data_reg     	      <= 0;
		io_resp_valid_reg    	      <= 0;
		io_busy_reg          	      <= 0;
		io_cmd_ready_reg     	      <= 0;
		target_latency		      <= 0;
		//$display("in reset Time = %0t", $time);
	end
	else 
	begin
		io_resp_valid_reg   <= 0;	
		//io_cmd_ready_reg     <= 0;
		//$display("funct=%0d, input_valid=%0b, output_ready=%0b, flag=%0b, time=%0t", io_cmd_bits_inst_funct, input_valid, output_ready, flag, $time);

		if(io_cmd_bits_inst_funct == 2 && input_valid == 1 && flag == 0) begin //COMPUTE
			target_latency <= LATENCY;
			//$display("MMIO in compute Time = %0t with Latency=%0d", $time, target_latency);

		end
		else if(io_cmd_bits_inst_funct == 1 && io_cmd_valid == 1 && flag == 0) begin //CONFIG
			target_latency <= 4;
	          			
			//$display("in config Time = %0t", $time);
	
		end

		if(target_latency != 0 && flag == 0) //recive command.
		begin
			//$display("MMIO started computing latency %0d", target_latency);
			//$display("got here");
			counter <= 0;
			flag    <= 1;
			//io_cmd_ready_reg <= 1;
			io_busy_reg <= 1;
		
		end
		
		if(flag)
		begin
			
			counter <= counter + 1;
			if(counter == target_latency) // finish command count
			begin
				//$display("finished counting counter==target_latency");	
				flag 		  <= 0;
				counter 	  <= 0;
				io_resp_valid_reg <= 1;
				target_latency    <= 0;
				io_resp_data_reg  <= 8'd06;
				//io_busy_reg       <= 0;
			end
			
		end // falg
		//if(io_resp_valid_reg)
		//	io_busy_reg <= 0;

		if(io_resp_valid_reg && ~output_ready) begin
			// keep the output_valid alive untill read from it
			//$display("got to this stupid point of gshahhen");
			io_resp_valid_reg <= 1;
		end
		
		if(io_resp_valid_reg & output_ready) // give back the data to the cpu.
		begin
			//$display("got the output_ready");	
			io_resp_data_reg  <= 8'd06;
		        io_resp_valid_reg <= 1;	
			flag2             <= 1;
		end

		if(flag2)
		begin
			io_resp_valid_reg <= 0;
			flag2             <= 0;
			io_busy_reg       <= 0;
		//	io_resp_valid_reg <= 1;
			flag <= 0;
			//io_cmd_ready_reg  <= 1;
		end

		if (io_cmd_bits_inst_funct == 1) begin
			reg_array[io_cmd_bits_inst_funct] <= io_cmd_bits_inst_funct; //FIXME	
		end

		//$display("output_valid=%0b, input_ready=%0b, time=%0t", output_valid, input_ready, $time);
		
	end // reset

end


assign data_out		      = io_resp_data_reg;
assign output_valid 	      = io_resp_valid_reg;
assign busy 		      = io_busy_reg;
//assign input_ready	      = io_cmd_ready_reg;
assign input_ready            = ~io_busy_reg;
assign io_cmd_bits_inst_funct = funct_cfg_reg;
assign io_cmd_valid	      = input_valid;

endmodule


