`include "src/cpu/cpu_defines.svinc"





//module Cpu(input bit clk,
//
//	// If an interrupt is being requested
//	input bit req_interrupt,
//
//	// If the CPU is enabled (can be used to stall it while memory access
//	// is being performed)
//	input bit enable,
//
//
//	input bit [`CPU_DATA_BUS_MAX_MSB_POS:0] data_in,
//	output pkg_cpu::StrcOutCpu out);
//
//
//	// Package imports
//	import pkg_cpu::*;
//
//
//	// Parameters
//	parameter counter_reset_val = -2;
//	parameter counter_done_val = -1;
//
//
//
//	// Local vars (not connections to other modules)
//	// All the registers, as well as flags and whether interrupts are
//	// enabled
//	pkg_cpu::StrcCpuSpecRegs __spec_regs;
//
//	// General purpose registers
//	bit [`CPU_WORD_MSB_POS:0] __gprs
//		[0:`WIDTH_TO_MSB_POS(pkg_cpu::num_gprs)];
//
//	pkg_cpu::State __state;
//
//	bit __waiting_for_divmod;
//	bit [`CPU_WORD_MSB_POS:0] __counter;
//
//	//bit __instr_is_alu_op;
//
//
//
//	// Connections to the Long ArithLog modules
//	bit [pkg_cpu::long_arithlog_operand_msb_pos:0] 
//		long_bitshift_a, long_bitshift_b;
//	bit [`CPU_WORD_MSB_POS:0] long_mul_a, long_mul_b;
//	wire [pkg_cpu::long_arithlog_operand_msb_pos:0] 
//		long_lsl_out, long_lsr_out, long_asr_out,
//		long_umul_out, long_smul_out;
//
//
//
//	// Connections to instr_dec
//	wire [`CPU_DATA_BUS_MAX_MSB_POS:0] instr_dec_to_decode = data_in;
//	pkg_instr_enc::StrcOutInstrDecoder instr_dec_out;
//
//	// Connections to the PlainAdder's
//	wire [`CPU_ADDR_BUS_MSB_POS:0] pc_adder_2_b = 2,
//		pc_adder_4_b = 4, pc_adder_6_b = 6;
//
//	wire [`CPU_ADDR_BUS_MSB_POS:0] pc_adder_2_out, pc_adder_4_out, 
//		pc_adder_6_out; 
//
//	// Connections to PlainAddThree's
//	wire [`CPU_WORD_MSB_POS:0] 
//		pc_addthree_branch_b = __instr_dec_out_buf.imm_val_s16,
//		pc_addthree_branch_c = pc_adder_4_b;
//	wire [`CPU_ADDR_BUS_MSB_POS:0] pc_addthree_branch_out;
//
//	
//	// Connections to the PlainAdder's/PlainSubtractor's
//	wire [`CPU_WORD_MSB_POS:0] 
//		oper_plain_subtractor_a = __instr_dec_out_buf.oper,
//		ig02_nf_alu_oc_b = pkg_cpu::Add_RaRb_0,
//		ig02_f_alu_oc_b = pkg_cpu::AddDotF_RaRb_0,
//		ig1_f_alu_oc_b = pkg_cpu::AddiDotF_RaRbUImm16_1,
//
//		// Push/Pop flags addsub a input
//		pushpop_flags_addsub_a = __gprs[pkg_cpu::sp_reg_index],
//
//		// Push/Pop flags addsub b input
//		pushpop_flags_addsub_b = 1,
//
//		// Block move pointer adder/subtractor a input
//		blkmov_ptr_addsub_a = __gprs[__instr_dec_out_buf.rx_index],
//
//		// Block move pointer adder/subtractor b inputs
//		blkmov_ptr_addsub_4_b = 4, blkmov_ptr_addsub_8_b = 8,
//		blkmov_ptr_addsub_12_b = 12, 
//
//		blkmov_ptr_addsub_16_b = 16, blkmov_ptr_addsub_20_b = 20,
//		blkmov_ptr_addsub_24_b = 24, blkmov_ptr_addsub_28_b = 28,
//		blkmov_ptr_addsub_32_b = 32,
//
//		// callx/jumpx destination calculator inputs
//		callx_or_jumpx_dst_adder_a = __gprs[__instr_dec_out_buf.ra_index],
//		callx_or_jumpx_dst_adder_b = __gprs[__instr_dec_out_buf.rb_index];
//
//
//	wire [`CPU_WORD_MSB_POS:0] ig02_nf_alu_oc_out, ig02_f_alu_oc_out,
//		ig1_f_alu_oc_out, 
//		branch_taken_oc_out,
//
//		// Push flags subtractor output
//		push_flags_subtractor_out,
//
//		// Pop flags adder output
//		pop_flags_adder_out, 
//
//		// Block move pointer adder outputs
//		blkmov_ptr_adder_4_out, blkmov_ptr_adder_8_out,
//		blkmov_ptr_adder_12_out, blkmov_ptr_adder_16_out,
//		blkmov_ptr_adder_20_out, blkmov_ptr_adder_24_out,
//		blkmov_ptr_adder_28_out, blkmov_ptr_adder_32_out,
//
//		// Block move pointer subtractor outputs
//		blkmov_ptr_subtractor_4_out, blkmov_ptr_subtractor_8_out,
//		blkmov_ptr_subtractor_12_out, blkmov_ptr_subtractor_16_out,
//		blkmov_ptr_subtractor_20_out, blkmov_ptr_subtractor_24_out,
//		blkmov_ptr_subtractor_28_out, blkmov_ptr_subtractor_32_out,
//
//		// callx/jumpx destination calculator output
//		callx_or_jumpx_dst_adder_out;
//	
//	// Connections to the SignExtender16 and SignExtender8
//	wire [`CPU_WORD_MSB_POS:0] 
//		ig0_seh_signext16_in = __gprs[__instr_dec_out_buf.rb_index],
//
//		ig0_seb_signext8_in = __gprs[__instr_dec_out_buf.rb_index];
//	
//	wire [`CPU_WORD_MSB_POS:0]
//		ig0_seh_signext16_out, ig0_seb_signext8_out;
//
//
//	// Connections to alu
//	pkg_cpu::StrcInAlu alu_in;
//	pkg_cpu::StrcOutAlu alu_out;
//
//
//	// Connections to small_alu
//	pkg_cpu::StrcInSmallAlu small_alu_in;
//	pkg_cpu::StrcOutSmallAlu small_alu_out;
//
//
//	// Connections to divmod32
//	struct packed
//	{
//		bit enable, unsgn_or_sgn;
//		bit [31:0] num, denom;
//	} divmod32_in;
//
//	struct packed
//	{
//		bit [31:0] quot, rem;
//		bit can_accept_cmd, data_ready;
//	} divmod32_out;
//
//	// Connections to divmod64
//	struct packed
//	{
//		bit enable, unsgn_or_sgn;
//		bit [63:0] num, denom;
//	} divmod64_in;
//
//	struct packed
//	{
//		bit [63:0] quot, rem;
//		bit can_accept_cmd, data_ready;
//	} divmod64_out;
//
//
//	// Temporaries
//	//bit [`CPU_WORD_MSB_POS:0] __temp[0:15];
//
//	// Copies of module outputs
//	pkg_cpu::StrcOutAlu __alu_out_buf;
//	pkg_cpu::StrcOutSmallAlu __smal_alu_out_buf;
//	pkg_instr_enc::StrcOutInstrDecoder __instr_dec_out_buf;
//
//
//	//bit [`CPU_WORD_MSB_POS:0] 
//	//	__wbs_uimm16,
//	//	__wbs_alu_out, __wbs_alu_flags_out, 
//
//	//	__wbs_dst, __wbs_branch_taken,
//
//	//	__wbs_seh_out, __wbs_seb_out,
//
//
//	pkg_cpu::StrcCpuRegWriteBackStuff
//		__wbs_ra, __wbs_rb, __wbs_rc, __wbs_lr, __wbs_sp,
//
//		__wbs_pc, __wbs_ira, __wbs_flags, __wbs_ints_enabled;
//
//
//
//	// Tasks
//	task set_alu_a_b;
//		input [`CPU_WORD_MSB_POS:0] some_a, some_b;
//
//		{alu_in.a, alu_in.b} = {some_a, some_b};
//	endtask
//
//	task init_alu;
//		input [`CPU_WORD_MSB_POS:0] some_a, some_b;
//		input [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] some_oper;
//
//		set_alu_a_b(some_a, some_b);
//		alu_in.oper = some_oper;
//		alu_in.flags = __spec_regs.flags;
//	endtask
//
//	`include "src/cpu/cpu_tasks.svinc"
//
//
//
//	initial
//	begin
//		for (byte i=0; i<pkg_cpu::num_gprs; i=i+1)
//		begin
//			__gprs[i] = 0;
//		end
//
//
//		__spec_regs.pc = 0;
//		__spec_regs.ira = 0;
//		__spec_regs.flags = 0;
//
//		__spec_regs.ints_enabled = 0;
//
//		__state = pkg_cpu::StInit;
//	end
//
//
//	// Sequential logic
//	always @ (posedge clk)
//	begin
//		if (enable)
//		begin
//			if (__state == pkg_cpu::StInit)
//			begin
//				prep_load_instr();
//			end
//
//			else if (__state == pkg_cpu::StDecodeInstr)
//			begin
//				if (__spec_regs.ints_enabled && req_interrupt)
//				begin
//					// Keep the same state
//
//					__spec_regs.ira <= __spec_regs.pc;
//					__spec_regs.pc <= pkg_cpu::irq_jump_location;
//					__spec_regs.ints_enabled <= 1'b0;
//					prep_read(pkg_cpu::ReqDataSz32,
//						pkg_cpu::irq_jump_location);
//				end
//				else
//				begin
//					__state <= pkg_cpu::StExecInstr;
//
//					__instr_dec_out_buf <= instr_dec_out;
//
//
//					long_bitshift_a <= {__gprs[instr_dec_out.rc_index],
//						__gprs[instr_dec_out.rd_index]};
//					long_bitshift_b <= {__gprs[instr_dec_out.re_index],
//						__gprs[instr_dec_out.rf_index]};
//					long_mul_a <= __gprs[instr_dec_out.rc_index];
//					long_mul_b <= __gprs[instr_dec_out.rd_index];
//
//					__waiting_for_divmod <= 0;
//					__counter <= counter_reset_val;
//
//
//					// This is going to need a fix of some sort when I
//					// eventually switch to a pipeline!
//
//
//					// It might be of interest to use a circular buffer
//					// that each instruction in the pipeline is associated
//					// with.
//					__wbs_ra <= 0;
//					__wbs_rb <= 0;
//					__wbs_rc <= 0;
//					__wbs_lr <= 0;
//					__wbs_sp <= 0;
//
//					__wbs_pc <= 0;
//					__wbs_ira <= 0;
//					__wbs_flags <= 0;
//					__wbs_ints_enabled <= 0;
//
//
//					// Disable reading/writing
//					disab_rdwr();
//
//					case (instr_dec_out.group)
//						// 16-bit (2 bytes)
//						2'b00:
//						begin
//							__spec_regs.pc <= pc_adder_2_out;
//						end
//
//						// 32-bit (4 bytes)
//						2'b01:
//						begin
//							__spec_regs.pc <= pc_adder_4_out;
//						end
//
//						// 32-bit (4 bytes)
//						2'b10:
//						begin
//							__spec_regs.pc <= pc_adder_4_out;
//						end
//
//						// 48-bit (6 bytes)
//						2'b11:
//						begin
//							__spec_regs.pc <= pc_adder_6_out;
//						end
//					endcase
//				end
//			end
//
//			// Note that this state may take multiple cycles to complete if
//			// either a block move is being performed or an integer
//			// division is being performed.
//			else if (__state == pkg_cpu::StExecInstr)
//			begin
//				//// For eventual conversion to use a pipeline, go ahead and
//				//// always go to pkg_cpu::StWriteBack every time.
//				//__state <= pkg_cpu::StWriteBack;
//				case (__instr_dec_out_buf.group)
//					2'b00:
//					begin
//						exec_seq_logic_group_0_instr_exec_stage();
//					end
//
//					2'b01:
//					begin
//						exec_seq_logic_group_1_instr_exec_stage();
//					end
//
//					2'b10:
//					begin
//						exec_seq_logic_group_2_instr_exec_stage();
//					end
//
//					2'b11:
//					begin
//						exec_seq_logic_group_3_instr_exec_stage();
//					end
//				endcase
//			end
//
//
//			else if (__state == pkg_cpu::StWriteBack)
//			begin
//				//{divmod32_in.enable, divmod64_in.enable} <= 0;
//				__state <= pkg_cpu::StDecodeInstr;
//				prep_load_instr();
//				exec_instr_write_back_stage();
//			end
//		end
//	end
//
//	// Combinational logic
//	//always_comb // your hair
//	always @ (*)
//	begin
//		if (enable)
//		begin
//			if (__state == pkg_cpu::StExecInstr)
//			begin
//				case (__instr_dec_out_buf.group)
//					2'b00:
//					begin
//						exec_comb_logic_group_0_instr_exec_stage();
//					end
//
//					2'b01:
//					begin
//						exec_comb_logic_group_1_instr_exec_stage();
//					end
//
//					2'b10:
//					begin
//						exec_comb_logic_group_2_instr_exec_stage();
//					end
//
//					2'b11:
//					begin
//						exec_comb_logic_group_3_instr_exec_stage();
//					end
//				endcase
//			end
//		end
//	end
//
//
//	`include "src/cpu/cpu_internal_modules.svinc"
//
//endmodule
