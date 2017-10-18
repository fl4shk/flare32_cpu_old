`include "src/cpu_defines.svinc"



module Alu(input wire [`CPU_WORD_MSB_POS:0] a_in, b_in, c_in,
	input bit [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] oper,
	input bit [`CPU_FLAGS_MSB_POS:0] flags_in,

	output bit [`CPU_WORD_MSB_POS:0] out,
	output bit [`CPU_FLAGS_MSB_POS:0] flags_out);



	// Package imports
	import pkg_cpu::*;


	// Local wires
	wire [`CPU_WORD_MSB_POS:0] rot_mod_thing;
	wire [`CPU_WORD_WIDTH + `CPU_WORD_WIDTH 
		+ `CPU_WORD_WIDTH + `CPU_WORD_WIDTH - 1 : 0] rot_temp;

	// Note that using `WIDTH_TO_MSB_POS in this way ONLY works if
	// `CPU_WORD_WIDTH and friends are powers of two.
	assign rot_mod_thing = `WIDTH_TO_MSB_POS(`CPU_WORD_WIDTH);
	assign rot_temp = {a_in, a_in};

	// This task is used by both adding and subtracting to update the V
	// flag.
	task update_v_flag;
		//input some_a_in_msb, some_b_in_msb, some_result_in_msb;
		//output some_proc_flag_v_out;
		//
		//some_proc_flag_v_out = ((some_a_in_msb ^ some_b_in_msb)
		//	& (some_a_in_msb ^ some_result_in_msb));
		flags_out[pkg_cpu::FlagV]
			= ((a_in[`CPU_WORD_MSB_POS] ^ b_in[`CPU_WORD_MSB_POS])
			& (a_in[`CPU_WORD_MSB_POS] ^ out[`CPU_WORD_MSB_POS]));
	endtask
	task update_n_and_z_flags;
		{flags_out[pkg_cpu::FlagN], flags_out[pkg_cpu::FlagZ]}
			= {out[`CPU_WORD_MSB_POS], out[0]};
	endtask

	//always_comb
	always @ (*)
	begin
		case (oper)
			pkg_cpu::Alu_Add:
			begin
				{flags_out[pkg_cpu::FlagC], out} = {1'b0, a_in} 
					+ {1'b0, b_in};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Adc:
			begin
				{flags_out[pkg_cpu::FlagC], out} = {1'b0, a_in} 
					+ {1'b0, b_in}
					+ {`CPU_WORD_WIDTH'b0, flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Sub:
			begin
				{flags_out[pkg_cpu::FlagC], out} = {1'b0, a_in} 
					+ {1'b0, (~b_in)} 
					+ {`CPU_WORD_WIDTH'b0, 1'b1};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Sbc:
			begin
				//{ proc_flags_out[pkg_pflags::pf_slot_c], out_lo } 
				//	= { 1'b0, a_in_lo } + { 1'b0, (~b_in_lo) } 
				//	+ { 8'h0, proc_flags_in[pkg_pflags::pf_slot_c] };
				{flags_out[pkg_cpu::FlagC], out} = {1'b0, a_in} 
					+ {1'b0, (~b_in)} 
					+ {`CPU_WORD_WIDTH'b0, flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Rsb:
			begin
				{flags_out[pkg_cpu::FlagC], out} = {1'b0, b_in} 
					+ {1'b0, (~a_in)} 
					+ {`CPU_WORD_WIDTH'b0, 1'b1};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Mul:
			begin
				out = a_in * b_in;
				flags_out = flags_in;
			end
			pkg_cpu::Alu_And:
			begin
				out = a_in & b_in;
				{flags_out[pkg_cpu::FlagV], flags_out[pkg_cpu::FlagC]}
					= {flags_in[pkg_cpu::FlagV], flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
			end
			pkg_cpu::Alu_Or:
			begin
				out = a_in | b_in;
				{flags_out[pkg_cpu::FlagV], flags_out[pkg_cpu::FlagC]}
					= {flags_in[pkg_cpu::FlagV], flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
			end
			pkg_cpu::Alu_Xor:
			begin
				out = a_in ^ b_in;
				{flags_out[pkg_cpu::FlagV], flags_out[pkg_cpu::FlagC]}
					= {flags_in[pkg_cpu::FlagV], flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
			end
			pkg_cpu::Alu_Lsl:
			begin
				out = a_in << b_in;
				flags_out = flags_in;
			end
			pkg_cpu::Alu_Lsr:
			begin
				out = a_in >> b_in;
				flags_out = flags_in;
			end
			pkg_cpu::Alu_Asr:
			begin
				out = $signed(a_in >>> b_in);
				flags_out = flags_in;
			end
			pkg_cpu::Alu_Rol:
			begin
				//rot_p_temp[(`alu_inout_pair_width 
				//- (b_in_lo & rot_p_mod_thing)) 
				//+: `alu_inout_pair_width]
				out = rot_temp[(`CPU_WORD_WIDTH - (b_in & rot_mod_thing)) 
					+: `CPU_WORD_WIDTH];
				flags_out = flags_in;
			end
			pkg_cpu::Alu_Ror:
			begin
				//rot_p_temp[(b_in_lo & rot_p_mod_thing) 
				//+: `alu_inout_pair_width]
				out = rot_temp[(b_in & rot_mod_thing) +: `CPU_WORD_WIDTH];
				flags_out = flags_in;
			end

			pkg_cpu::Alu_Rlc:
			begin
				//{ proc_flags_out[pkg_pflags::pf_slot_c], 
				//	{ out_hi, out_lo } } = { { a_in_hi, a_in_lo }, 
				//	proc_flags_in[pkg_pflags::pf_slot_c] };
				{flags_out[pkg_cpu::FlagC], out}
					= {b_in, flags_in[pkg_cpu::FlagC]};
				{flags_out[pkg_cpu::FlagN], flags_out[pkg_cpu::FlagV],
					flags_out[pkg_cpu::FlagZ]}
					= {flags_in[pkg_cpu::FlagN], flags_in[pkg_cpu::FlagV],
					flags_in[pkg_cpu::FlagZ]};
			end

			pkg_cpu::Alu_Rrc:
			begin
				//{ { out_hi, out_lo }, 
				//	proc_flags_out[pkg_pflags::pf_slot_c] }
				//	= { proc_flags_in[pkg_pflags::pf_slot_c],
				//	{ a_in_hi, a_in_lo } };
				//proc_flags_out[pkg_pflags::pf_slot_c] }
				{out, flags_out[pkg_cpu::FlagC]}
					= {flags_in[pkg_cpu::FlagC], b_in};
				{flags_out[pkg_cpu::FlagN], flags_out[pkg_cpu::FlagV],
					flags_out[pkg_cpu::FlagZ]}
					= {flags_in[pkg_cpu::FlagN], flags_in[pkg_cpu::FlagV],
					flags_in[pkg_cpu::FlagZ]};
			end


			// Used mainly for ldst rA, [rB, rC, simm12]
			pkg_cpu::Alu_AddThree:
			begin
				out = a_in + b_in + c_in;
				flags_out = flags_in;
			end

			// Fused multiply-add
			pkg_cpu::Alu_Fma:
			begin
				out = a_in + (b_in * c_in);
				flags_out = flags_in;
			end
		endcase
	end

endmodule
