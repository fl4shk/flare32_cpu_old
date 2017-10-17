`include "src/cpu_defines.svinc"

// Combinational logic to decode an instruction
module InstrDecoder(input bit [`CPU_INSTR_MAX_MSB_POS:0] to_decode,


	// Instruction group
	output bit [`CPU_INSTR_ENC_GROUP_MSB_POS:0] group,

	// If this instruction is permitted to affect flags
	output bit might_affect_flags,

	// The 5-bit operation within the particular group
	output bit [`CPU_INSTR_ENC_OPER_MSB_POS:0] oper,


	// Register indices
	output bit [`CPU_INSTR_ENC_REG_INDEX_MSB_POS:0] 
		ra_index, rb_index, rc_index, rd_index, 
		re_index, rf_index, rg_index, rh_index, 
		rx_index,


	// Immediate values
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_2,
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_u16,
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_s16,
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_s12,
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_32);


	// Package imports
	import pkg_instr_enc::*;


	// Local wires
	wire [`CPU_HALF_WORD_MSB_POS:0] __hw0, __hw1, __hw2;


	// Assignments
	assign {__hw0, __hw1, __hw2} = to_decode;


	// Same for every instruction
	assign group = __hw0[pkg_instr_enc::hw0_enc_group__high
		: pkg_instr_enc::hw0_enc_group__low];
	assign might_affect_flags 
		= __hw0[pkg_instr_enc::hw0_might_affect_flags__bit];
	assign oper = __hw0[pkg_instr_enc::hw0_oper__high
		: pkg_instr_enc::hw0_oper__low];
	
	assign ra_index = __hw0[pkg_instr_enc::hw0_ra_index__high
		: pkg_instr_enc::hw0_ra_index__low];
	assign rb_index = __hw0[pkg_instr_enc::hw0_rb_index__high
		: pkg_instr_enc::hw0_rb_index__low];


	// Zero extension
	assign imm_val_u16 = {16'h0000, __hw1};

	// No extension needed
	assign imm_val_32 = {__hw1, __hw2};


	// Block moves
	assign imm_val_2 = (group == 2) 
		? (__hw1[pkg_instr_enc::g2_blk_hw1_num_regs__high
		: pkg_instr_enc::g2_blk_hw1_num_regs__low])
		: (__hw2[pkg_instr_enc::g3_blk_hw2_num_regs__high
		: pkg_instr_enc::g3_blk_hw2_num_regs__low]);


	// Sign extension
	assign imm_val_s16 = (__hw1[`CPU_INSTR_ENC_SIMM16_MSB_POS:0])
		? {16'hffff, __hw1[`CPU_INSTR_ENC_SIMM16_MSB_POS:0]} 
		: {16'h0000, __hw1[`CPU_INSTR_ENC_SIMM16_MSB_POS:0]};

	// Sign extension
	assign imm_val_s12 = (__hw1[`CPU_INSTR_ENC_SIMM12_MSB_POS:0])
		? {20'hfffff, __hw1[`CPU_INSTR_ENC_SIMM12_MSB_POS:0]} 
		: {20'h00000, __hw1[`CPU_INSTR_ENC_SIMM12_MSB_POS:0]};

	
	// This applies to both group 2 and group 3 instructions
	assign {rc_index, rd_index}
		= __hw1[pkg_instr_enc::g2_hw1_rc_index__high
		: pkg_instr_enc::g2_blk_hw1_rd_index__low];

	// Block moves
	assign rx_index = (group == 2)
		? (__hw1[pkg_instr_enc::g2_blk_hw1_rx_index__high
		: pkg_instr_enc::g2_blk_hw1_rx_index__low])
		: (__hw2[pkg_instr_enc::g3_blk_hw2_rx_index__high
		: pkg_instr_enc::g3_blk_hw2_rx_index__low]);


	// Group 3 only
	assign {re_index, rf_index, rg_index, rh_index}
		= {__hw1[pkg_instr_enc::g3__hw1_re_index__high
		: pkg_instr_enc::g3__hw1_rf_index__low],
		__hw2[pkg_instr_enc::g3__hw2_rg_index__high
		: pkg_instr_enc::g3__hw2_rh_index__low]};

endmodule
