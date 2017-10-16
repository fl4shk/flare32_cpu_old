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
		reg_a_index, reg_b_index, reg_c_index, reg_d_index, 
		reg_e_index, reg_f_index, reg_g_index, reg_h_index, 
		reg_x_index,


	// Immediate values
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_2,
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_u16,
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_s16,
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_s12,
	output bit [`CPU_INSTR_ENC_MAX_IMM_VALUE_MSB_POS:0] imm_val_32);


	// Package imports
	import pkg_cpu::*;



	// Local wires
	wire [`CPU_HALF_WORD_MSB_POS:0] __hw0, __hw1, __hw2;


	// Assignments
	assign {__hw0, __hw1, __hw2} = to_decode;


	// Same for every instruction
	assign group = __hw0[`CPU_IE_HW0_ENC_GROUP__HIGH_BIT
		:`CPU_IE_HW0_ENC_GROUP__LOW_BIT];
	assign might_affect_flags = __hw0[`CPU_IE_HW0_MIGHT_AFFECT_FLAGS__BIT];
	assign oper = __hw0[`CPU_IE_HW0_OPER__HIGH_BIT
		:`CPU_IE_HW0_OPER__LOW_BIT];
	
	assign reg_a_index = __hw0[`CPU_IE_HW0_REG_A_INDEX__HIGH_BIT
		:`CPU_IE_HW0_REG_A_INDEX__LOW_BIT];
	assign reg_b_index = __hw0[`CPU_IE_HW0_REG_B_INDEX__HIGH_BIT
		:`CPU_IE_HW0_REG_B_INDEX__LOW_BIT];


	// Zero extension
	assign imm_val_u16 = {16'h0000, __hw1};

	// No extension needed
	assign imm_val_32 = {__hw1, __hw2};


	// Block moves
	assign imm_val_2 = (group == 2) 
		? (__hw1[`CPU_IE_G2_BLK_HW1_NUM_REGS__HIGH_BIT
		:`CPU_IE_G2_BLK_HW1_NUM_REGS__LOW_BIT])
		: (__hw2[`CPU_IE_G3_BLK_HW2_NUM_REGS__HIGH_BIT
		:`CPU_IE_G3_BLK_HW2_NUM_REGS__LOW_BIT]);


	// Sign extension
	assign imm_val_s16 = (__hw1[`CPU_INSTR_ENC_SIMM16_MSB_POS:0])
		? {16'hffff, __hw1[`CPU_INSTR_ENC_SIMM16_MSB_POS:0]} 
		: {16'h0000, __hw1[`CPU_INSTR_ENC_SIMM16_MSB_POS:0]};

	// Sign extension
	assign imm_val_s12 = (__hw1[`CPU_INSTR_ENC_SIMM12_MSB_POS:0])
		? {20'hfffff, __hw1[`CPU_INSTR_ENC_SIMM12_MSB_POS:0]} 
		: {20'h00000, __hw1[`CPU_INSTR_ENC_SIMM12_MSB_POS:0]};

	
	// This applies to both group 2 and group 3 instructions
	assign {reg_c_index, reg_d_index}
		= __hw1[`CPU_IE_G2_HW1_REG_C_INDEX__HIGH_BIT
		:`CPU_IE_G2_BLK_HW1_REG_D_INDEX__LOW_BIT];

	// Block moves
	assign reg_x_index = (group == 2)
		? (__hw1[`CPU_IE_G2_BLK_HW1_REG_X_INDEX__HIGH_BIT
		:`CPU_IE_G2_BLK_HW1_REG_X_INDEX__LOW_BIT])
		: (__hw2[`CPU_IE_G3_BLK_HW2_REG_X_INDEX__HIGH_BIT
		:`CPU_IE_G3_BLK_HW2_REG_X_INDEX__LOW_BIT]);


	// Group 3 only
	assign {reg_e_index, reg_f_index, reg_g_index, reg_h_index}
		= {__hw1[`CPU_IE_G3_MULTI_REGS_HW1_REG_E_INDEX__HIGH_BIT
		:`CPU_IE_G3_MULTI_REGS_HW1_REG_F_INDEX__LOW_BIT],
		__hw2[`CPU_IE_G3_MULTI_REGS_HW2_REG_G_INDEX__HIGH_BIT
		:`CPU_IE_G3_MULTI_REGS_HW2_REG_H_INDEX__LOW_BIT]};

endmodule
