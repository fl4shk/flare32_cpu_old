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


	// Local vars (not connections to other modules)
	// All the registers, as well as flags and whether interrupts are
	// enabled
	pkg_cpu::StrcCpuSpecRegs __spec_regs;

	// General purpose registers
	bit [`CPU_WORD_MSB_POS:0] __gprs
		[0:`WIDTH_TO_MSB_POS(pkg_cpu::num_regs)];

	pkg_cpu::State __state;

	bit __instr_is_alu_op;


	// Connections to the PcAdder's
	wire [`CPU_ADDR_BUS_MSB_POS:0] pc_adder_2_add_amount,
		pc_adder_4_add_amount, pc_adder_6_add_amount,
		pc_adder_branch_add_amount;
	wire [`CPU_ADDR_BUS_MSB_POS:0] pc_adder_2_pc_out,
		pc_adder_4_pc_out, pc_adder_6_pc_out, pc_adder_branch_pc_out;

	// Connections to the Long ArithLog modules
	bit [pkg_cpu::long_arithlog_operand_msb_pos:0] 
		long_bitshift_a, long_bitshift_b;
	bit [`CPU_WORD_MSB_POS:0] long_mul_a, long_mul_b;
	wire [pkg_cpu::long_arithlog_operand_msb_pos:0] 
		long_lsl_out, long_lsr_out, long_asr_out,
		long_umul_out, long_smul_out;



	// Connections to instr_dec
	wire [`CPU_DATA_BUS_MAX_MSB_POS:0] instr_dec_to_decode;
	pkg_instr_enc::StrcOutInstrDecoder instr_dec_out;



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


	// Temporaries
	bit [`CPU_WORD_MSB_POS:0] __temp0, __temp1;

	// Copies of module outputs
	pkg_cpu::StrcOutAlu __alu_out_buf;
	pkg_cpu::StrcOutSmallAlu __smal_alu_out_buf;
	pkg_instr_enc::StrcOutInstrDecoder __instr_dec_out_buf;


	// Assignments
	assign instr_dec_to_decode = data_in;


	assign pc_adder_2_add_amount = 2;
	assign pc_adder_4_add_amount = 4;
	assign pc_adder_6_add_amount = 6;

	// Since we don't know if the branch happened until late into
	// execution, use __instr_dec_out_buf instead of instr_dec_out.
	assign pc_adder_branch_add_amount = __instr_dec_out_buf.imm_val_s16;


	//assign long_bitshift_a = {__gprs[__instr_dec_out_buf.rc_index],
	//	__gprs[__instr_dec_out_buf.rd_index]};
	//assign long_bitshift_b = {__gprs[__instr_dec_out_buf.re_index],
	//	__gprs[__instr_dec_out_buf.rf_index]};
	//assign long_mul_a = __gprs[__instr_dec_out_buf.rc_index];
	//assign long_mul_b = __gprs[__instr_dec_out_buf.rd_index];


	// Tasks
	task set_alu_a_b;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;

		{alu_in.a, alu_in.b} = {some_a, some_b};
	endtask

	task init_alu;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;
		input [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] some_oper;
		input [`CPU_ENUM_FLAGS_POS_MSB_POS:0] some_flags;

		set_alu_a_b(some_a, some_b);
		alu_in.oper = some_oper;
		alu_in.flags = some_flags;
	endtask

	`include "src/cpu/cpu_tasks.svinc"



	initial
	begin
		{__gprs[0], __gprs[1], __gprs[2], __gprs[3],
		__gprs[4], __gprs[5], __gprs[6], __gprs[7],
		__gprs[8], __gprs[9], __gprs[10], __gprs[11],
		__gprs[12], __gprs[13], __gprs[14], __gprs[15]} = 0;


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
							__spec_regs.pc <= pc_adder_2_pc_out;
						end

						// 32-bit (4 bytes)
						2'b01:
						begin
							//__spec_regs.pc <= __spec_regs.pc + 4;
							__spec_regs.pc <= pc_adder_4_pc_out;
						end

						// 32-bit (4 bytes)
						2'b10:
						begin
							//__spec_regs.pc <= __spec_regs.pc + 4;
							__spec_regs.pc <= pc_adder_4_pc_out;
						end

						// 48-bit (6 bytes)
						2'b11:
						begin
							//__spec_regs.pc <= __spec_regs.pc + 6;
							__spec_regs.pc <= pc_adder_6_pc_out;
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
	PcAdder pc_adder_2(.pc_in(__spec_regs.pc),
		.add_amount(pc_adder_2_add_amount), .pc_out(pc_adder_2_pc_out));
	PcAdder pc_adder_4(.pc_in(__spec_regs.pc),
		.add_amount(pc_adder_4_add_amount), .pc_out(pc_adder_4_pc_out));
	PcAdder pc_adder_6(.pc_in(__spec_regs.pc),
		.add_amount(pc_adder_6_add_amount), .pc_out(pc_adder_6_pc_out));
	PcAdder pc_adder_branch(.pc_in(__spec_regs.pc),
		.add_amount(pc_adder_branch_add_amount),
		.pc_out(pc_adder_branch_pc_out));

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
