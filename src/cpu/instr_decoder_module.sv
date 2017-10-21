`include "src/cpu/cpu_defines.svinc"

// Combinational logic to decode an instruction
module InstrDecoder(input bit [`CPU_INSTR_MAX_MSB_POS:0] to_decode,


	output pkg_instr_enc::StrcOutInstrDecoder out);




	// Package imports
	import pkg_instr_enc::*;


	// Local wires
	wire [`CPU_HALF_WORD_MSB_POS:0] __hw0, __hw1, __hw2;
	wire [3:0] __alu_can_affect_flags;



	// Assignments
	assign {__hw0, __hw1, __hw2} = to_decode;


	// Group 0 instructions
	assign __alu_can_affect_flags[0]
		= (((out.oper >= pkg_cpu::AddDotF_RaRb_0)
		&& (out.oper <= pkg_cpu::Rrc_RaRb_0))
		|| (out.oper == pkg_cpu::Cmp_RaRb_0));
	
	// Group 1 instructions
	assign __alu_can_affect_flags[1]
		= ((out.oper >= pkg_cpu::AddiDotF_RaRbUImm16_1)
		&& (out.oper <= pkg_cpu::RoriDotF_RaRbUImm16_1));
	
	// Group 2 instructions
	assign __alu_can_affect_flags[2]
		= ((out.oper >= pkg_cpu::AddDotF_RaRbRc_2)
		&& (out.oper <= pkg_cpu::RorDotF_RaRbRc_2));

	// Group 3 instructions
	assign __alu_can_affect_flags[3]
		= 0;


	// Same for every instruction
	assign out.group = __hw0[pkg_instr_enc::hw0_enc_group__high
		: pkg_instr_enc::hw0_enc_group__low];



	assign out.oper = __hw0[pkg_instr_enc::hw0_oper__high
		: pkg_instr_enc::hw0_oper__low];

	assign out.alu_can_affect_flags = __alu_can_affect_flags[out.group];

	assign out.ra_index = __hw0[pkg_instr_enc::hw0_ra_index__high
		: pkg_instr_enc::hw0_ra_index__low];
	assign out.rb_index = __hw0[pkg_instr_enc::hw0_rb_index__high
		: pkg_instr_enc::hw0_rb_index__low];


	// Zero extension
	assign out.imm_val_u16 = {16'h0000, __hw1};

	// No extension needed
	assign out.imm_val_32 = {__hw1, __hw2};


	// Block moves
	assign out.imm_val_2 = (out.group == 2) 
		? (__hw1[pkg_instr_enc::block_move_num_regs__high
		: pkg_instr_enc::block_move_num_regs__low])
		: (__hw2[pkg_instr_enc::block_move_num_regs__high
		: pkg_instr_enc::block_move_num_regs__low]);


	// Sign extension of 16-bit immediate
	assign out.imm_val_s16 = (__hw1[`CPU_INSTR_ENC_SIMM16_MSB_POS])
		? {16'hffff, __hw1[`CPU_INSTR_ENC_SIMM16_MSB_POS:0]} 
		: {16'h0000, __hw1[`CPU_INSTR_ENC_SIMM16_MSB_POS:0]};

	// Sign extension of 12-bit immediate
	assign out.imm_val_s12 = (__hw1[`CPU_INSTR_ENC_SIMM12_MSB_POS])
		? {20'hfffff, __hw1[`CPU_INSTR_ENC_SIMM12_MSB_POS:0]} 
		: {20'h00000, __hw1[`CPU_INSTR_ENC_SIMM12_MSB_POS:0]};

	
	// This applies to both group 2 and group 3 instructions
	assign {out.rc_index, out.rd_index}
		= __hw1[pkg_instr_enc::multi_regs_rc_index__high
		: pkg_instr_enc::multi_regs_rd_index__low];

	// Block moves
	assign out.rx_index = (out.group == 2)
		? (__hw1[pkg_instr_enc::block_move_rx_index__high
		: pkg_instr_enc::block_move_rx_index__low])
		: (__hw2[pkg_instr_enc::block_move_rx_index__high
		: pkg_instr_enc::block_move_rx_index__low]);


	// Group 3 only
	assign {out.re_index, out.rf_index, out.rg_index, out.rh_index}
		= {__hw1[pkg_instr_enc::multi_regs_re_index__high
		: pkg_instr_enc::multi_regs_rf_index__low],
		__hw2[pkg_instr_enc::multi_regs_rg_index__high
		: pkg_instr_enc::multi_regs_rh_index__low]};

endmodule
