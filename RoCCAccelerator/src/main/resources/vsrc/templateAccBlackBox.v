/*
* Accelerator module (generic template).
* Fits both types - MMIO and RoCC accelerators.
* Counts latency.
*/

`define ASSERT_VERBOSE_COND 0

module templateAccBlackBox#
(
// Define module parameters (the accelerator's traits)
  parameter int DATA_WIDTH 	   = 64,    // Data width in bits.
  parameter int ADDR_WIDTH 	   = 64,   // Address width in bits.
  parameter int CFG_REG_WIDTH      = 64,   // number of register bits.
  parameter int NUM_OF_CFG_REGS    = 3,    // depends on many variables?
  parameter int MEM_DATA_WIDTH     = 64,    // number of bits used to transfer data between a MMIO accelerator and the system memory. This parameter defines the size of the data bus used for memory transactions.
  parameter int BUFF_SIZE          = 32,   // Buffer size in bytes. helps our memory access.
  parameter int LATENCY   	   = 500,  // later, this should be per instruction - opcode. Latency is the time required for the accelerator to complete a single operation.
  parameter int MEMORY_BANDWIDTH   = 300   // measured in bps (bytes per second), this should be a unique accelerator trait. affects performance.
//parameter int pipeline
)

(
//define the inputs/outputs
	input 	  clock,
	input 	  reset,

// RoCC interface
// CPU -> Accelerator. recieve a command from the CPU.
	input 	  io_cmd_valid,
	output 	  io_cmd_ready,
	input  [6:0]  io_cmd_bits_inst_funct,
	input  [4:0]  io_cmd_bits_inst_rs2,
	input  [4:0]  io_cmd_bits_inst_rs1,  // This is the register number. there are 32 registers.
	input  [4:0]  io_cmd_bits_inst_rd,
	input  [6:0]  io_cmd_bits_inst_opcode,
	input  [63:0] io_cmd_bits_rs1,  
	input  [63:0] io_cmd_bits_rs2,

// RoCC interface. 
// Accelerator -> CPU (Rocket/BOOM), give the CPU the calculated data
	input         io_resp_ready,
	output        io_resp_valid,
	output [4:0]  io_resp_bits_rd,
	output [63:0] io_resp_bits_data,

// MMIO interface. 
// Accelerator --> Memory
	//input         io_mem_req_ready,
	//output        io_mem_req_valid,
	//output [39:0] io_mem_req_bits_addr,
	//output [7:0]  io_mem_req_bits_tag,
	//output [4:0]  io_mem_req_bits_cmd,
	//output [1:0]  io_mem_req_bits_size,
	//output        io_mem_req_bits_signed,
	//output        io_mem_req_bits_no_alloc,
	//output        io_mem_req_bits_no_xcpt,
	//output [63:0] io_mem_req_bits_data,
	//output [7:0]  io_mem_req_bits_mask,

// MMIO interface. 
// Memory --> Accelerator
	//input         io_mem_resp_valid,
	//input  [39:0] io_mem_resp_bits_addr,
	//input  [7:0]  io_mem_resp_bits_tag,
	//input  [4:0]  io_mem_resp_bits_cmd,
	//input  [1:0]  io_mem_resp_bits_size,
	//input         io_mem_resp_bits_signed,
	//input  [1:0]  io_mem_resp_bits_dprv,
	//input         io_mem_resp_bits_dv,
	//input  [63:0] io_mem_resp_bits_data

  input         io_cmd_bits_inst_xd,
  input         io_cmd_bits_inst_xs1,
  input         io_cmd_bits_inst_xs2,
  input         io_cmd_bits_status_debug,
  input         io_cmd_bits_status_cease,
  input         io_cmd_bits_status_wfi,
  input  [31:0] io_cmd_bits_status_isa,
  input  [1:0]  io_cmd_bits_status_dprv,
  input         io_cmd_bits_status_dv,
  input  [1:0]  io_cmd_bits_status_prv,
  input         io_cmd_bits_status_v,
  input         io_cmd_bits_status_sd,
  input  [22:0] io_cmd_bits_status_zero2,
  input         io_cmd_bits_status_mpv,
  input         io_cmd_bits_status_gva,
  input         io_cmd_bits_status_mbe,
  input         io_cmd_bits_status_sbe,
  input  [1:0]  io_cmd_bits_status_sxl,
  input  [1:0]  io_cmd_bits_status_uxl,
  input         io_cmd_bits_status_sd_rv32,
  input  [7:0]  io_cmd_bits_status_zero1,
  input         io_cmd_bits_status_tsr,
  input         io_cmd_bits_status_tw,
  input         io_cmd_bits_status_tvm,
  input         io_cmd_bits_status_mxr,
  input         io_cmd_bits_status_sum,
  input         io_cmd_bits_status_mprv,
  input  [1:0]  io_cmd_bits_status_xs,
  input  [1:0]  io_cmd_bits_status_fs,
  input  [1:0]  io_cmd_bits_status_mpp,
  input  [1:0]  io_cmd_bits_status_vs,
  input         io_cmd_bits_status_spp,
  input         io_cmd_bits_status_mpie,
  input         io_cmd_bits_status_ube,
  input         io_cmd_bits_status_spie,
  input         io_cmd_bits_status_upie,
  input         io_cmd_bits_status_mie,
  input         io_cmd_bits_status_hie,
  input         io_cmd_bits_status_sie,
  input         io_cmd_bits_status_uie,
  input         io_mem_req_ready,
  output        io_mem_req_valid,
  output [39:0] io_mem_req_bits_addr,
  output [7:0]  io_mem_req_bits_tag,
  output [4:0]  io_mem_req_bits_cmd,
  output [1:0]  io_mem_req_bits_size,
  output        io_mem_req_bits_signed,
  output [1:0]  io_mem_req_bits_dprv,
  output        io_mem_req_bits_dv,
  output        io_mem_req_bits_phys,
  output        io_mem_req_bits_no_alloc,
  output        io_mem_req_bits_no_xcpt,
  output [63:0] io_mem_req_bits_data,
  output [7:0]  io_mem_req_bits_mask,
  output        io_mem_s1_kill,
  output [63:0] io_mem_s1_data_data,
  output [7:0]  io_mem_s1_data_mask,
  input         io_mem_s2_nack,
  input         io_mem_s2_nack_cause_raw,
  output        io_mem_s2_kill,
  input         io_mem_s2_uncached,
  input  [31:0] io_mem_s2_paddr,
  input         io_mem_resp_valid,
  input  [39:0] io_mem_resp_bits_addr,
  input  [7:0]  io_mem_resp_bits_tag,
  input  [4:0]  io_mem_resp_bits_cmd,
  input  [1:0]  io_mem_resp_bits_size,
  input         io_mem_resp_bits_signed,
  input  [1:0]  io_mem_resp_bits_dprv,
  input         io_mem_resp_bits_dv,
  input  [63:0] io_mem_resp_bits_data,
  input  [7:0]  io_mem_resp_bits_mask,
  input         io_mem_resp_bits_replay,
  input         io_mem_resp_bits_has_data,
  input  [63:0] io_mem_resp_bits_data_word_bypass,
  input  [63:0] io_mem_resp_bits_data_raw,
  input  [63:0] io_mem_resp_bits_store_data,
  input         io_mem_replay_next,
  input         io_mem_s2_xcpt_ma_ld,
  input         io_mem_s2_xcpt_ma_st,
  input         io_mem_s2_xcpt_pf_ld,
  input         io_mem_s2_xcpt_pf_st,
  input         io_mem_s2_xcpt_gf_ld,
  input         io_mem_s2_xcpt_gf_st,
  input         io_mem_s2_xcpt_ae_ld,
  input         io_mem_s2_xcpt_ae_st,
  input  [39:0] io_mem_s2_gpa,
  input         io_mem_s2_gpa_is_pte,
  input         io_mem_ordered,
  input         io_mem_perf_acquire,
  input         io_mem_perf_release,
  input         io_mem_perf_grant,
  input         io_mem_perf_tlbMiss,
  input         io_mem_perf_blocked,
  input         io_mem_perf_canAcceptStoreThenLoad,
  input         io_mem_perf_canAcceptStoreThenRMW,
  input         io_mem_perf_canAcceptLoadThenLoad,
  input         io_mem_perf_storeBufferEmptyAfterLoad,
  input         io_mem_perf_storeBufferEmptyAfterStore,
  output        io_mem_keep_clock_enabled,
  input         io_mem_clock_enabled,
  output        io_busy,
  output        io_interrupt,
  input         io_exception,
  input         io_fpu_req_ready,
  output        io_fpu_req_valid,
  output        io_fpu_req_bits_ldst,
  output        io_fpu_req_bits_wen,
  output        io_fpu_req_bits_ren1,
  output        io_fpu_req_bits_ren2,
  output        io_fpu_req_bits_ren3,
  output        io_fpu_req_bits_swap12,
  output        io_fpu_req_bits_swap23,
  output [1:0]  io_fpu_req_bits_typeTagIn,
  output [1:0]  io_fpu_req_bits_typeTagOut,
  output        io_fpu_req_bits_fromint,
  output        io_fpu_req_bits_toint,
  output        io_fpu_req_bits_fastpipe,
  output        io_fpu_req_bits_fma,
  output        io_fpu_req_bits_div,
  output        io_fpu_req_bits_sqrt,
  output        io_fpu_req_bits_wflags,
  output [2:0]  io_fpu_req_bits_rm,
  output [1:0]  io_fpu_req_bits_fmaCmd,
  output [1:0]  io_fpu_req_bits_typ,
  output [1:0]  io_fpu_req_bits_fmt,
  output [64:0] io_fpu_req_bits_in1,
  output [64:0] io_fpu_req_bits_in2,
  output [64:0] io_fpu_req_bits_in3,
  output        io_fpu_resp_ready,
  input         io_fpu_resp_valid,
  input  [64:0] io_fpu_resp_bits_data,
  input  [4:0]  io_fpu_resp_bits_exc
);

reg [4:0] io_resp_rd_reg;
reg [4:0] io_resp_rd_reg_temp;
reg [63:0] io_resp_data_reg;
reg io_resp_valid_reg;
reg io_busy_reg;
reg io_fpu_req_valid_reg;
reg io_interrupt_reg;
reg io_mem_req_valid_reg;
reg io_cmd_ready_reg;
reg io_mem_s2_kill_reg;
reg io_mem_keep_clock_enabled_reg;


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
		io_resp_rd_reg       	      <= 0;
		io_resp_valid_reg    	      <= 0;
		io_busy_reg          	      <= 0;
		io_fpu_req_valid_reg 	      <= 0;
		io_interrupt_reg    	      <= 0;
		io_mem_req_valid_reg 	      <= 0;
		io_cmd_ready_reg     	      <= 0;
		io_mem_s2_kill_reg   	      <= 0;
		io_mem_keep_clock_enabled_reg <= 1;
		io_resp_rd_reg_temp	      <= 0;
		target_latency		      <= 0;
	end
	else 
	begin
		
	//	io_busy_reg 	     <= 0;
		io_fpu_req_valid_reg <= 0;
		io_interrupt_reg     <= 0;
		io_mem_req_valid_reg <= 0;
		//this
		//io_cmd_ready_reg     <= 0;
		io_mem_s2_kill_reg   <= 0;
		io_mem_keep_clock_enabled_reg <= 1;
		io_resp_valid_reg <= 0;
		flag2 <= 0;

		if(io_cmd_bits_inst_funct == 2 && io_cmd_valid == 1 && flag == 0) begin //COMPUTE
			target_latency <= LATENCY;
			$display("in compute Time = %0t", $time);
			io_resp_rd_reg_temp <= io_cmd_bits_inst_rd;

		end
		else if(io_cmd_bits_inst_funct == 1 && io_cmd_valid == 1 && flag == 0) begin //CONFIG
			target_latency <= 4;
	          	io_resp_rd_reg_temp <= io_cmd_bits_inst_rd;	
			$display("in config Time = %0t", $time);
	
		end

		if(target_latency != 0) //recive command.
		begin
			counter <= 0;
			flag    <= 1;
			//this
			//io_cmd_ready_reg <= 1;
			//this down
			//io_resp_rd_reg_temp <= io_cmd_bits_inst_rd;
			io_busy_reg <= 1;
		
		end
		
		if(flag)
		begin
			
			counter <= counter + 1;
			//io_cmd_ready_reg <= 1;
			if(counter == target_latency) // finish command count
			begin
				
				flag 		  <= 0;
				counter 	  <= 0;
				io_resp_valid_reg <= 1;
				target_latency    <= 0;
				io_resp_rd_reg   <= io_resp_rd_reg_temp;
				io_resp_data_reg <= 8'd06;
			end
			
		end // falg
		
		if(io_resp_valid_reg & io_resp_ready & !flag2) // give back the data to the cpu.
		begin
		
		//	io_resp_rd_reg   <= io_resp_rd_reg_temp;
		//	io_resp_data_reg <= 8'd06;
		        //io_resp_valid_reg<= 1;

			flag2            <= 1;
			io_busy_reg <= 0;
			io_cmd_ready_reg <= 1;
			//io_busy_reg      <= 1;
		end

	//	if(flag2)
	//	begin
	//		io_resp_valid_reg <= 1;
	//		flag2             <= 0;
	//		io_busy_reg       <= 0;
	//		// this
	//		io_cmd_ready_reg  <= 1;
	//	end

		if (io_cmd_bits_inst_funct == 1) begin
			reg_array[io_cmd_bits_inst_rs1] <= io_cmd_bits_inst_rs1;	
		end
		
	end // reset

end


assign io_resp_bits_data = io_resp_data_reg;
assign io_resp_bits_rd 	 = io_resp_rd_reg;
assign io_resp_valid 	 = io_resp_valid_reg;
assign io_busy 		 = io_busy_reg;
assign io_interrupt 	 = io_interrupt_reg;
assign io_fpu_req_valid  = io_fpu_req_valid_reg;
assign io_mem_req_valid  = io_mem_req_valid_reg;
//this
//assign io_cmd_ready	 = io_cmd_ready_reg;
assign io_cmd_ready = ~io_busy_reg;
assign io_mem_s2_kill	 = io_mem_s2_kill_reg;
assign io_mem_keep_clock_enabled = io_mem_keep_clock_enabled_reg;

endmodule
