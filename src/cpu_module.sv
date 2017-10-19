`include "src/cpu_defines.svinc"



module Cpu(input bit clk,

	// If an interrupt is being requested
	input bit req_interrupt,


	input bit [`CPU_DATA_BUS_MAX_MSB_POS:0] data_in,
	output pkg_cpu::StrcOutCpu out);


	// Package imports
	import pkg_cpu::*;

	


	//always @ (posedge clk)
	//begin
	//end


endmodule
