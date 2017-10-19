`include "src/cpu_defines.svinc"



module Cpu(input bit clk,

	// If an interrupt is being requested
	input bit req_interrupt,


	input bit [`CPU_DATA_BUS_MAX_MSB_POS:0] data_in,
	output pkg_cpu::StrcOutCpu out);


	// Package imports
	import pkg_cpu::*;

	// All the registers
	pkg_cpu::StrcCpuRegs __regs;

	// Temporaries
	bit [`CPU_WORD_MSB_POS:0] __temp0, __temp1;


	//always @ (posedge clk)
	//begin
	//end


endmodule
