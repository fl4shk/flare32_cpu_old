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
	import pkg_cpu::*;

	// Parameters

	// Encoding group
	parameter hw0_enc_group__high = 15;
	parameter hw0_enc_group__low = 14;



	// If flags are possible to change (some instructions don't affect
	// flags anyway though)
	//
	// I guess "pop flags" discards the results despite affecting the stack
	// pointer?  I might want to change that....
	parameter hw0_might_affect_flags__bit = 13;



	// What type of operation (add, sub, ldr, mul, subi, etc.)
	parameter hw0_oper__high = 12;
	parameter hw0_oper__low = 8;


	// rA
	parameter hw0_ra_index__high = 7;
	parameter hw0_ra_index__low = 4;


	// rB
	parameter hw0_rb_index__high = 3;
	parameter hw0_rb_index__low = 0;




	// Peculiarities to Instruction Groups other than 0:


	// [Encoding of] Group 1 Instructions
	// 01fo oooo aaaa bbbb  iiii iiii iiii iiii

		// f:  1 if can affect flags (and instruction type supports it), 0
		// if flags unchanged.

		// o:  opcode
		// a: rA
		// b: rB
		// i:  16-bit immediate value


	// The 16-bit immediate value of a group 1 instruction:  
	parameter g1_hw1_imm_value__high = 15;
	parameter g1_hw1_imm_value__low = 0;
	// Well that's simple.






	// [Encoding of] Group 2 Instructions
	// Non Block Moves Version:  
		// 10fo oooo aaaa bbbb  cccc iiii iiii iiii

		// f:  1 if can affect flags (and instruction type supports it), 0
		// if flags unchanged.

		// o:  opcode
		// a: rA
		// b: rB
		// c: rC
		// i:  12-bit immediate value

	// Block Moves Version (stmdb, ldmia, stmia, push, pop):  
		// 10fo oooo aaaa bbbb  cccc dddd xxxx 00ii

		// f:  1 if can affect flags (and instruction type supports it), 0
		// if flags unchanged.

		// o:  opcode
		// a: rA
		// b: rB
		// c: rC
		// d: rD
		// x: rX
		// i:  2-bit immediate value


	// rC
	// Note that both block moves version and non block moves version group
	// 2 instructions have rC in their encoding
	parameter g2_hw1_rc_index__high = 15;
	parameter g2_hw1_rc_index__low = 12;


	// The 12-bit immediate value of a non-block move group 2 instruction:
	parameter g2_nonblk_hw1_imm_value__high = 11;
	parameter g2_nonblk_hw1_imm_value__low = 0;



	// Block move:  rD
	parameter g2_blk_hw1_rd_index__high = 11;
	parameter g2_blk_hw1_rd_index__low = 8;


	// Block move:  rX
	parameter g2_blk_hw1_rx_index__high = 7;
	parameter g2_blk_hw1_rx_index__low = 4;

	// Block move:  00
	parameter g2_blk_hw1_blank__high = 3;
	parameter g2_blk_hw1_blank__low = 2;

	// Block move:  00 for one address reg, 01 for two address regs, 10 for
	// three address regs, 11 for four address regs
	parameter g2_blk_hw1_num_regs__high = 1;
	parameter g2_blk_hw1_num_regs__low = 0;



	// Group 3 Instructions
	// Two Registers Version:  
		// 11fo oooo aaaa bbbb  iiii iiii iiii iiii  iiii iiii iiii iiii

		// f:  1 if can affect flags (and instruction type supports it), 0
		// if flags unchanged.

		// o:  opcode
		// a: rA
		// b: rB
		// i:  32-bit immediate value

	// More Than Two Registers Version (stmdb, ldmia, stmia, push, pop,
	// umul, smul, udivmod, sdivmod, lsl, lsr, asr):  
		// 11fo oooo aaaa bbbb  cccc dddd eeee ffff  gggg hhhh xxxx 00ii

		// f:  1 if can affect flags (and instruction type supports it), 0
		// if flags unchanged.

		// o:  opcode
		// a: rA
		// b: rB
		// c: rC
		// d: rD
		// Only Some Multi Regs Instructions:  e: rE
		// Only Some Multi Regs Instructions:  f: rF
		// Only Some Multi Regs Instructions:  g: rG
		// Only Some Multi Regs Instructions:  h: rH
		// Block Moves Only:  x: rX
		// Block Moves Only:  i:  2-bit immediate value


	// The 32-bit immediate of 48-bit instructions that involve only two
	// registers
	parameter g3_two_regs_hw1_imm_value__high = 15;
	parameter g3_two_regs_hw1_imm_value__low = 0;
	parameter g3_two_regs_hw2_imm_value__high = 15;
	parameter g3_two_regs_hw2_imm_value__low = 0;



	// More than two registers:  rC index
	parameter g3__hw1_rc_index__high = 15;
	parameter g3__hw1_rc_index__low = 12;

	// More than two registers:  rD index
	parameter g3__hw1_rd_index__high = 11;
	parameter g3__hw1_rd_index__low = 8;

	// More than two registers:  rE index
	parameter g3__hw1_re_index__high = 7;
	parameter g3__hw1_re_index__low = 4;

	// More than two registers:  rF index
	parameter g3__hw1_rf_index__high = 3;
	parameter g3__hw1_rf_index__low = 0;



	// More than two registers:  rG index
	parameter g3__hw2_rg_index__high = 15;
	parameter g3__hw2_rg_index__low = 12;

	// More than two registers:  rH index
	parameter g3__hw2_rh_index__high = 11;
	parameter g3__hw2_rh_index__low = 8;


	// Block move:  rX index
	parameter g3_blk_hw2_rx_index__high = 7;
	parameter g3_blk_hw2_rx_index__low = 4;


	// Block move:  00
	parameter g3_blk_hw2_blank__high = 3;
	parameter g3_blk_hw2_blank__low = 2;

	// Block move:  00 for five address regs, 01 for six address regs, 10
	// for seven address regs, 11 for eight address regs
	parameter g3_blk_hw2_num_regs__high = 1;
	parameter g3_blk_hw2_num_regs__low = 0;

	// Local wires
	wire [`CPU_HALF_WORD_MSB_POS:0] __hw0, __hw1, __hw2;


	// Assignments
	assign {__hw0, __hw1, __hw2} = to_decode;


	// Same for every instruction
	assign group = __hw0[hw0_enc_group__high:hw0_enc_group__low];
	assign might_affect_flags = __hw0[hw0_might_affect_flags__bit];
	assign oper = __hw0[hw0_oper__high:hw0_oper__low];
	
	assign ra_index = __hw0[hw0_ra_index__high:hw0_ra_index__low];
	assign rb_index = __hw0[hw0_rb_index__high:hw0_rb_index__low];


	// Zero extension
	assign imm_val_u16 = {16'h0000, __hw1};

	// No extension needed
	assign imm_val_32 = {__hw1, __hw2};


	// Block moves
	assign imm_val_2 = (group == 2) 
		? (__hw1[g2_blk_hw1_num_regs__high:g2_blk_hw1_num_regs__low])
		: (__hw2[g3_blk_hw2_num_regs__high:g3_blk_hw2_num_regs__low]);


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
		= __hw1[g2_hw1_rc_index__high:g2_blk_hw1_rd_index__low];

	// Block moves
	assign rx_index = (group == 2)
		? (__hw1[g2_blk_hw1_rx_index__high:g2_blk_hw1_rx_index__low])
		: (__hw2[g3_blk_hw2_rx_index__high:g3_blk_hw2_rx_index__low]);


	// Group 3 only
	assign {re_index, rf_index, rg_index, rh_index}
		= {__hw1[g3__hw1_re_index__high:g3__hw1_rf_index__low],
		__hw2[g3__hw2_rg_index__high:g3__hw2_rh_index__low]};

endmodule
