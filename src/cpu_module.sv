`include "src/cpu_defines.svinc"



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

	// All the registers, as well as flags and whether interrupts are
	// enabled
	pkg_cpu::StrcCpuStorage __stor;

	pkg_cpu::State __state;

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

	// Tasks
	task set_alu_a_b;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;

		{alu_in.a_in, alu_in.b_in} = {some_a, some_b};
	endtask

	task init_alu;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;
		input [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] some_oper;
		input [`CPU_ENUM_FLAGS_POS_MSB_POS:0] some_flags_in;

		set_alu_a_b(some_a, some_b);
		alu_in.oper = some_oper;
		alu_in.flags_in = some_flags_in;
	endtask

	`include "src/cpu_tasks.svinc"



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
		if (enable)
		begin
			if (__state == pkg_cpu::StInit)
			begin
				prep_load_instr();
			end

			else if (__state == pkg_cpu::StDecodeInstr)
			begin
				if (__stor.ints_enabled && req_interrupt)
				begin
					// Keep the same state

					__stor.ira <= __stor.pc;
					__stor.pc <= pkg_cpu::irq_jump_location;
					__stor.ints_enabled <= 1'b0;
					prep_read(pkg_cpu::ReqDataSz32,
						pkg_cpu::irq_jump_location);
				end
				else
				begin
					__state <= pkg_cpu::StStartExecInstr;

					__instr_dec_out_buf <= instr_dec_out;

					// Disable reading/writing
					disab_rdwr();

					case (instr_dec_out.group)
						// 16-bit (2 bytes)
						2'b00:
						begin
							__stor.pc <= __stor.pc + 2;
						end

						// 32-bit (4 bytes)
						2'b01:
						begin
							__stor.pc <= __stor.pc + 4;
						end

						// 32-bit (4 bytes)
						2'b10:
						begin
							__stor.pc <= __stor.pc + 4;
						end

						// 48-bit (6 bytes)
						2'b11:
						begin
							__stor.pc <= __stor.pc + 6;
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
	InstrDecoder instr_dec(.to_decode(instr_dec_to_decode),
		.out(instr_dec_out));
	Alu alu(.in(alu_in), .out(alu_out));
	SmallAlu small_alu(.in(small_alu_in), .out(small_alu_out));

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
