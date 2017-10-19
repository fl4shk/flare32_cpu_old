`include "src/cpu_defines.svinc"



module Cpu(input bit clk,

	// If an interrupt is being requested
	input bit req_interrupt,


	input bit [`CPU_DATA_BUS_MAX_MSB_POS:0] data_in,
	output pkg_cpu::StrcOutCpu out);


	// Package imports
	import pkg_cpu::*;

	// All the registers, as well as flags and whether interrupts are
	// enabled
	pkg_cpu::StrcCpuStorage __stor;

	pkg_cpu::State __state;

	// Connections to instr_dec
	wire [`CPU_DATA_BUS_MAX_MSB_POS:0] instr_dec_to_decode;
	pkg_instr_enc::StrcOutInstrDecoder instr_dec_out;

	pkg_instr_enc::StrcOutInstrDecoder __instr_dec_out_buf;


	// Connections to alu
	pkg_cpu::StrcInAlu alu_in;
	pkg_cpu::StrcOutAlu alu_out;

	// Connections to small_alu
	pkg_cpu::StrcInSmallAlu small_alu_in;
	pkg_cpu::StrcOutSmallAlu small_alu_out;

	// Temporaries
	bit [`CPU_WORD_MSB_POS:0] __temp0, __temp1;

	initial
	begin
		{__stor.gpr[0], __stor.gpr[1], __stor.gpr[2], __stor.gpr[3],
		__stor.gpr[4], __stor.gpr[5], __stor.gpr[6], __stor.gpr[7],
		__stor.gpr[8], __stor.gpr[9], __stor.gpr[10], __stor.gpr[11],
		__stor.gpr[12], __stor.gpr[13], __stor.gpr[14], __stor.gpr[15]}
			= 0;

		__stor.pc = 0;
		__stor.ira = 0;
		__stor.flags = 0;

		__stor.ints_enabled = 0;

		__state = pkg_cpu::StInit;
	end


	always @ (posedge clk)
	begin
		if (__state == pkg_cpu::StInit)
		begin
			
		end

		else if (__state == pkg_cpu::StDecodeInstr)
		begin
			
		end

		else if (__state == pkg_cpu::StAcceptInterrupt)
		begin
			
		end

		else if (__state == pkg_cpu::StExecNonLdSt)
		begin
			
		end

		else if (__state == pkg_cpu::StExecLdStPart0)
		begin
			
		end

		else if (__state == pkg_cpu::StExecLdStPart1)
		begin
			
		end
	end


	//always_comb // your hair
	always @ (*)
	begin
		if (__state == pkg_cpu::StInit)
		begin
			
		end

		else if (__state == pkg_cpu::StDecodeInstr)
		begin
			
		end

		else if (__state == pkg_cpu::StAcceptInterrupt)
		begin
			
		end

		else if (__state == pkg_cpu::StExecNonLdSt)
		begin
			
		end

		else if (__state == pkg_cpu::StExecLdStPart0)
		begin
			
		end

		else if (__state == pkg_cpu::StExecLdStPart1)
		begin
			
		end
	end


	// Module instantiations
	InstrDecoder instr_dec(.to_decode(instr_dec_to_decode),
		.out(instr_dec_out));
	Alu alu(.in(alu_in), .out(alu_out));
	SmallAlu small_alu(.in(small_alu_in), .out(small_alu_out));

endmodule
