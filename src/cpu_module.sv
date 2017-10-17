`include "src/cpu_defines.svinc"


module Cpu(input bit clk, enable,

	// Request an interrupt
	input bit req_interrupt,

	

	output bit [`CPU_ENUM_REQ_DATA_SIZE_MSB_POS:0] req_data_size,
	output bit [`CPU_DATA_BUS_MAX_MSB_POS:0] data_out,

	output bit [`CPU_ADDR_BUS_MSB_POS:0] addr_out,

	// Request anything, request a write specifically
	output bit req_rdwr, req_write);


endmodule
