`include "src/cpu_defines.svinc"



module Alu(input bit [`CPU_WORD_MSB_POS:0] a, b, c,
	input bit [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] oper,
	input bit [`CPU_FLAGS_MSB_POS:0] flags_in,

	output bit [`CPU_WORD_MSB_POS:0] out,
	output bit [`CPU_FLAGS_MSB_POS:0] flags_out);



	// Package imports
	import pkg_cpu::*;

	//always_comb
	always @ (*)
	begin
		
	end

endmodule
