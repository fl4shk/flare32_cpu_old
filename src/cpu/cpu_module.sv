`include "src/cpu/cpu_defines.svinc"





module Cpu(input bit clk,

	// If an interrupt is being requested
	input bit req_interrupt,

	// If the CPU is enabled (can be used to stall it while memory access
	// is being performed)
	input bit enable,


	input bit [`CPU_DATA_BUS_MAX_MSB_POS:0] data_in,
	output pkg_cpu::StrcOutCpu out);


	// Package imports
	import pkg_cpu::*;
	import pkg_temp_ind_0::*;

	

	// Local vars (not connections to other modules)
	// All the registers, as well as flags and whether interrupts are
	// enabled
	pkg_cpu::StrcCpuSpecRegs __spec_regs;

	// General purpose registers
	bit [`CPU_WORD_MSB_POS:0] __gprs
		[0:`WIDTH_TO_MSB_POS(pkg_cpu::num_gprs)];

	pkg_cpu::State __state;

	bit __instr_is_alu_op;



	// Connections to the Long ArithLog modules
	bit [pkg_cpu::long_arithlog_operand_msb_pos:0] 
		long_bitshift_a, long_bitshift_b;
	bit [`CPU_WORD_MSB_POS:0] long_mul_a, long_mul_b;
	wire [pkg_cpu::long_arithlog_operand_msb_pos:0] 
		long_lsl_out, long_lsr_out, long_asr_out,
		long_umul_out, long_smul_out;



	// Connections to instr_dec
	wire [`CPU_DATA_BUS_MAX_MSB_POS:0] instr_dec_to_decode = data_in;
	pkg_instr_enc::StrcOutInstrDecoder instr_dec_out;

	// Connections to the PlainAdder's
	wire [`CPU_ADDR_BUS_MSB_POS:0] pc_adder_2_b = 2,
		pc_adder_4_b = 4, pc_adder_6_b = 6;

	// Since we don't know if the branch happened until late into
	// execution, use __instr_dec_out_buf instead of instr_dec_out.
	wire [`CPU_ADDR_BUS_MSB_POS:0] pc_adder_branch_b
		= __instr_dec_out_buf.imm_val_s16;

	wire [`CPU_ADDR_BUS_MSB_POS:0] pc_adder_2_out, pc_adder_4_out, 
		pc_adder_6_out, pc_adder_branch_out;

	
	// Connections to the PlainAdder's/PlainSubtractor's
	wire [`CPU_WORD_MSB_POS:0] 
		oper_plain_subtractor_a = __instr_dec_out_buf.oper,
		ig02_nf_alu_oc_b = pkg_cpu::Add_RaRb_0,
		ig02_f_alu_oc_b = pkg_cpu::AddDotF_RaRb_0,
		ig1_f_alu_oc_b = pkg_cpu::AddiDotF_RaRbUImm16_1,

		// Push/Pop flags addsub a input
		pushpop_flags_addsub_a = __gprs[pkg_cpu::sp_reg_index],

		// Push/Pop flags addsub b input
		pushpop_flags_addsub_b = 1,

		// Block move pointer adder/subtractor a input
		blkmov_ptr_addsub_a = __gprs[__instr_dec_out_buf.rx_index],

		// Block move pointer adder/subtractor b inputs
		blkmov_ptr_addsub_4_b = 4, blkmov_ptr_addsub_8_b = 8,
		blkmov_ptr_addsub_12_b = 12, 

		blkmov_ptr_addsub_16_b = 16, blkmov_ptr_addsub_20_b = 20,
		blkmov_ptr_addsub_24_b = 24, blkmov_ptr_addsub_28_b = 28,
		blkmov_ptr_addsub_32_b = 32,

		// callx/jumpx destination calculator inputs
		callx_or_jumpx_dst_adder_a = __gprs[__instr_dec_out_buf.ra_index],
		callx_or_jumpx_dst_adder_b = __gprs[__instr_dec_out_buf.rb_index];


	wire [`CPU_WORD_MSB_POS:0] ig02_nf_alu_oc_out, ig02_f_alu_oc_out,
		ig1_f_alu_oc_out, 

		// Push flags subtractor output
		push_flags_subtractor_out,

		// Pop flags adder output
		pop_flags_adder_out, 

		// Block move pointer adder outputs
		blkmov_ptr_adder_4_out, blkmov_ptr_adder_8_out,
		blkmov_ptr_adder_12_out, blkmov_ptr_adder_16_out,
		blkmov_ptr_adder_20_out, blkmov_ptr_adder_24_out,
		blkmov_ptr_adder_28_out, blkmov_ptr_adder_32_out,

		// Block move pointer subtractor outputs
		blkmov_ptr_subtractor_4_out, blkmov_ptr_subtractor_8_out,
		blkmov_ptr_subtractor_12_out, blkmov_ptr_subtractor_16_out,
		blkmov_ptr_subtractor_20_out, blkmov_ptr_subtractor_24_out,
		blkmov_ptr_subtractor_28_out, blkmov_ptr_subtractor_32_out,

		// callx/jumpx destination calculator output
		callx_or_jumpx_dst_adder_out;

	// Connections to alu
	pkg_cpu::StrcInAlu alu_in;
	pkg_cpu::StrcOutAlu alu_out;


	// Connections to small_alu
	pkg_cpu::StrcInSmallAlu small_alu_in;
	pkg_cpu::StrcOutSmallAlu small_alu_out;


	// Connections to divmod32
	struct packed
	{
		bit enable, unsgn_or_sgn;
		bit [31:0] num, denom;
	} divmod32_in;

	struct packed
	{
		bit [31:0] quot, rem;
		bit can_accept_cmd, data_ready;
	} divmod32_out;

	// Connections to divmod64
	struct packed
	{
		bit enable, unsgn_or_sgn;
		bit [63:0] num, denom;
	} divmod64_in;

	struct packed
	{
		bit [63:0] quot, rem;
		bit can_accept_cmd, data_ready;
	} divmod64_out;


	//// Temporaries
	bit [`CPU_WORD_MSB_POS:0] __temp[0:7];

	// Copies of module outputs
	pkg_cpu::StrcOutAlu __alu_out_buf;
	pkg_cpu::StrcOutSmallAlu __smal_alu_out_buf;
	pkg_instr_enc::StrcOutInstrDecoder __instr_dec_out_buf;




	// Tasks
	task set_alu_a_b;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;

		{alu_in.a, alu_in.b} = {some_a, some_b};
	endtask

	task init_alu;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;
		input [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] some_oper;

		set_alu_a_b(some_a, some_b);
		alu_in.oper = some_oper;
		alu_in.flags = __spec_regs.flags;
	endtask

	`include "src/cpu/cpu_tasks.svinc"



	initial
	begin
		for (byte i=0; i<pkg_cpu::num_gprs; i=i+1)
		begin
			__gprs[i] = 0;
		end


		__spec_regs.pc = 0;
		__spec_regs.ira = 0;
		__spec_regs.flags = 0;

		__spec_regs.ints_enabled = 0;

		__state = pkg_cpu::StInit;
	end


	always @ (posedge clk)
	begin
		if (enable)
		begin
			if (__state == pkg_cpu::StInit)
			begin
				prep_load_instr();
			end

			else if (__state == pkg_cpu::StDecodeInstr)
			begin
				if (__spec_regs.ints_enabled && req_interrupt)
				begin
					// Keep the same state

					__spec_regs.ira <= __spec_regs.pc;
					__spec_regs.pc <= pkg_cpu::irq_jump_location;
					__spec_regs.ints_enabled <= 1'b0;
					prep_read(pkg_cpu::ReqDataSz32,
						pkg_cpu::irq_jump_location);
				end
				else
				begin
					__state <= pkg_cpu::StStartExecInstr;

					__instr_dec_out_buf <= instr_dec_out;


					long_bitshift_a <= {__gprs[instr_dec_out.rc_index],
						__gprs[instr_dec_out.rd_index]};
					long_bitshift_b <= {__gprs[instr_dec_out.re_index],
						__gprs[instr_dec_out.rf_index]};
					long_mul_a <= __gprs[instr_dec_out.rc_index];
					long_mul_b <= __gprs[instr_dec_out.rd_index];


					// Disable reading/writing
					disab_rdwr();

					case (instr_dec_out.group)
						// 16-bit (2 bytes)
						2'b00:
						begin
							//__spec_regs.pc <= __spec_regs.pc + 2;
							__spec_regs.pc <= pc_adder_2_out;
						end

						// 32-bit (4 bytes)
						2'b01:
						begin
							//__spec_regs.pc <= __spec_regs.pc + 4;
							__spec_regs.pc <= pc_adder_4_out;
						end

						// 32-bit (4 bytes)
						2'b10:
						begin
							//__spec_regs.pc <= __spec_regs.pc + 4;
							__spec_regs.pc <= pc_adder_4_out;
						end

						// 48-bit (6 bytes)
						2'b11:
						begin
							//__spec_regs.pc <= __spec_regs.pc + 6;
							__spec_regs.pc <= pc_adder_6_out;
						end
					endcase
				end
			end

			else if (__state == pkg_cpu::StStartExecInstr)
			begin
				// For eventual conversion to use a pipeline, go ahead and
				// always go to pkg_cpu::StFinishExecInstr every time.
				__state <= pkg_cpu::StFinishExecInstr;
				case (__instr_dec_out_buf.group)
					2'b00:
					begin
						exec_group_0_instr_part_0();
					end

					2'b01:
					begin
						exec_group_1_instr_part_0();
					end

					2'b10:
					begin
						exec_group_2_instr_part_0();
					end

					2'b11:
					begin
						exec_group_3_instr_part_0();
					end
				endcase
			end


			// Note that this state may take multiple cycles to complete if
			// either a block move is being performed or an integer
			// division is being performed.
			else if (__state == pkg_cpu::StFinishExecInstr)
			begin
				{divmod32_in.enable, divmod64_in.enable} <= 0;
				
				case (__instr_dec_out_buf.group)
					2'b00:
					begin
						exec_group_0_instr_part_1();
					end

					2'b01:
					begin
						exec_group_1_instr_part_1();
					end

					2'b10:
					begin
						exec_group_2_instr_part_1();
					end

					2'b11:
					begin
						exec_group_3_instr_part_1();
					end
				endcase
			end

			else if (__state == pkg_cpu::StWriteBack)
			begin
				prep_load_instr();
				case (__instr_dec_out_buf.group)
					2'b00:
					begin
						exec_group_0_instr_part_2();
					end

					2'b01:
					begin
						exec_group_1_instr_part_2();
					end

					2'b10:
					begin
						exec_group_2_instr_part_2();
					end

					2'b11:
					begin
						exec_group_3_instr_part_2();
					end
				endcase
			end
		end
	end


	// Module instantiations
	PlainAdder pc_adder_2(.a(__spec_regs.pc), .b(pc_adder_2_b), 
		.out(pc_adder_2_out));
	PlainAdder pc_adder_4(.a(__spec_regs.pc), .b(pc_adder_4_b), 
		.out(pc_adder_4_out));
	PlainAdder pc_adder_6(.a(__spec_regs.pc), .b(pc_adder_6_b), 
		.out(pc_adder_6_out));
	PlainAdder pc_adder_branch(.a(__spec_regs.pc), .b(pc_adder_branch_b),
		.out(pc_adder_branch_out));

	// Pop flags adder
	PlainAdder pop_flags_adder(.a(pushpop_flags_addsub_a),
		.b(pushpop_flags_addsub_b), .out(pop_flags_adder_out));

	// Block move pointer adders
	PlainAdder blkmov_ptr_adder_4(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_4_b), .out(blkmov_ptr_adder_4_out));
	PlainAdder blkmov_ptr_adder_8(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_8_b), .out(blkmov_ptr_adder_8_out));
	PlainAdder blkmov_ptr_adder_12(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_12_b), .out(blkmov_ptr_adder_12_out));
	PlainAdder blkmov_ptr_adder_16(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_16_b), .out(blkmov_ptr_adder_16_out));
	PlainAdder blkmov_ptr_adder_20(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_20_b), .out(blkmov_ptr_adder_20_out));
	PlainAdder blkmov_ptr_adder_24(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_24_b), .out(blkmov_ptr_adder_24_out));
	PlainAdder blkmov_ptr_adder_28(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_28_b), .out(blkmov_ptr_adder_28_out));
	PlainAdder blkmov_ptr_adder_32(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_32_b), .out(blkmov_ptr_adder_32_out));
	
	// callx/jumpx destination calculator
	PlainAdder callx_or_jumpx_dst_adder(.a(callx_or_jumpx_dst_adder_a),
		.b(callx_or_jumpx_dst_adder_b),
		.out(callx_or_jumpx_dst_adder_out));


	// "_nf_" means "non-flags"
	// This works for both instruction groups 0 and 2 due to how their
	// instructions are encoded.
	PlainSubtractor ig02_nf_alu_oper_calc(.a(oper_plain_subtractor_a),
		.b(ig02_nf_alu_oc_b), .out(ig02_nf_alu_oc_out));
	
	// "_f_" means "affects flags"
	// This works for both instruction groups 0 and 2 due to how their
	// instructions are encoded.
	PlainSubtractor ig02_f_alu_oper_calc(.a(oper_plain_subtractor_a),
		.b(ig02_f_alu_oc_b), .out(ig02_f_alu_oc_out));

	// We don't need a subtractor for non-flags group 1 instructions since
	// we'd just be subtracting zero anyway.
	PlainSubtractor ig1_f_alu_oper_calc(.a(oper_plain_subtractor_a),
		.b(ig1_f_alu_oc_b), .out(ig1_f_alu_oc_out));

	// Push flags subtractor
	PlainSubtractor push_flags_subtractor(.a(pushpop_flags_addsub_a),
		.b(pushpop_flags_addsub_b), .out(push_flags_subtractor_out));

	// Block move pointer subtractors
	PlainSubtractor blkmov_ptr_subtractor_4(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_4_b), .out(blkmov_ptr_subtractor_4_out));
	PlainSubtractor blkmov_ptr_subtractor_8(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_8_b), .out(blkmov_ptr_subtractor_8_out));
	PlainSubtractor blkmov_ptr_subtractor_12(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_12_b), .out(blkmov_ptr_subtractor_12_out));
	PlainSubtractor blkmov_ptr_subtractor_16(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_16_b), .out(blkmov_ptr_subtractor_16_out));
	PlainSubtractor blkmov_ptr_subtractor_20(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_20_b), .out(blkmov_ptr_subtractor_20_out));
	PlainSubtractor blkmov_ptr_subtractor_24(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_24_b), .out(blkmov_ptr_subtractor_24_out));
	PlainSubtractor blkmov_ptr_subtractor_28(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_28_b), .out(blkmov_ptr_subtractor_28_out));
	PlainSubtractor blkmov_ptr_subtractor_32(.a(blkmov_ptr_addsub_a),
		.b(blkmov_ptr_addsub_32_b), .out(blkmov_ptr_subtractor_32_out));



	// Long bitshifts
	LongLsl long_lsl(.a(long_bitshift_a), .b(long_bitshift_b),
		.out(long_lsl_out));
	LongLsl long_lsr(.a(long_bitshift_a), .b(long_bitshift_b),
		.out(long_lsr_out));
	LongLsl long_asr(.a(long_bitshift_a), .b(long_bitshift_b),
		.out(long_asr_out));

	// 32-bit * 32-bit -> 64-bit multipliers
	LongUMul long_umul(.a(long_mul_a), .b(long_mul_b),
		.out(long_umul_out));
	LongUMul long_smul(.a(long_mul_a), .b(long_mul_b),
		.out(long_smul_out));

	InstrDecoder instr_dec(.to_decode(instr_dec_to_decode),
		.out(instr_dec_out));
	Alu alu(.in(alu_in), .out(alu_out));
	SmallAlu small_alu(.in(small_alu_in), .out(small_alu_out));

	// Dividers
	NonRestoringDivider #(32) divmod32(.clk(clk),
		.enable(divmod32_in.enable), 
		.unsgn_or_sgn(divmod32_in.unsgn_or_sgn),
		.num(divmod32_in.num), .denom(divmod32_in.denom),
		.quot(divmod32_out.quot), .rem(divmod32_out.rem),
		.can_accept_cmd(divmod32_out.can_accept_cmd),
		.data_ready(divmod32_out.data_ready));
	NonRestoringDivider #(64) divmod64(.clk(clk),
		.enable(divmod64_in.enable), 
		.unsgn_or_sgn(divmod64_in.unsgn_or_sgn),
		.num(divmod64_in.num), .denom(divmod64_in.denom),
		.quot(divmod64_out.quot), .rem(divmod64_out.rem),
		.can_accept_cmd(divmod64_out.can_accept_cmd),
		.data_ready(divmod64_out.data_ready));

endmodule
