`include "src/cpu_defines.svinc"



module Alu(input pkg_cpu::StrcInAlu in, output pkg_cpu::StrcOutAlu out);
	// Package imports
	import pkg_cpu::*;


	// Local wires
	wire [`CPU_WORD_MSB_POS:0] __rot_mod_thing;
	wire [`CPU_WORD_WIDTH + `CPU_WORD_WIDTH 
		+ `CPU_WORD_WIDTH + `CPU_WORD_WIDTH - 1 : 0] __rot_temp;

	// Note that using `WIDTH_TO_MSB_POS in this way ONLY works if
	// `CPU_WORD_WIDTH and friends are powers of two.
	assign __rot_mod_thing = `WIDTH_TO_MSB_POS(`CPU_WORD_WIDTH);
	assign __rot_temp = {in.a_in, in.a_in};

	// This task is used by both adding and subtracting to update the V
	// flag.
	task update_v_flag;
		//input some_a_in_msb, some_b_in_msb, some_result_in_msb;
		//output some_proc_flag_v_out;
		//
		//some_proc_flag_v_out = ((some_a_in_msb ^ some_b_in_msb)
		//	& (some_a_in_msb ^ some_result_in_msb));
		//out.flags_out[pkg_cpu::FlagV]
		//	= !((in.a_in[`CPU_WORD_MSB_POS] ^ in.b_in[`CPU_WORD_MSB_POS])
		//	& (in.a_in[`CPU_WORD_MSB_POS] ^ out.out[`CPU_WORD_MSB_POS]));

		out.flags_out[pkg_cpu::FlagV]
			= ((in.a_in[`CPU_WORD_MSB_POS] ^ in.b_in[`CPU_WORD_MSB_POS])
			& (in.a_in[`CPU_WORD_MSB_POS] ^ out.out[`CPU_WORD_MSB_POS]));
		//out.flags_out[pkg_cpu::FlagV]
		//	= ((in.a_in[`CPU_WORD_MSB_POS] ^ out.out[`CPU_WORD_MSB_POS])
		//	& (in.b_in[`CPU_WORD_MSB_POS] ^ out.out[`CPU_WORD_MSB_POS]));
	endtask
	task update_n_and_z_flags;
		{out.flags_out[pkg_cpu::FlagN], out.flags_out[pkg_cpu::FlagZ]}
			= {out.out[`CPU_WORD_MSB_POS], (out.out == 0)};
	endtask

	//always_comb // your hair
	always @ (*)
	begin
		case (in.oper)
			pkg_cpu::Alu_Add:
			begin
				{out.flags_out[pkg_cpu::FlagC], out.out} = {1'b0, in.a_in} 
					+ {1'b0, in.b_in};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Adc:
			begin
				{out.flags_out[pkg_cpu::FlagC], out.out} = {1'b0, in.a_in} 
					+ {1'b0, in.b_in}
					+ {`CPU_WORD_WIDTH'b0, in.flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Sub:
			begin
				{out.flags_out[pkg_cpu::FlagC], out.out} = {1'b0, in.a_in} 
					+ {1'b0, (~in.b_in)} 
					+ {`CPU_WORD_WIDTH'b0, 1'b1};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Sbc:
			begin
				//{ proc_flags_out[pkg_pflags::pf_slot_c], out_lo } 
				//	= { 1'b0, a_in_lo } + { 1'b0, (~b_in_lo) } 
				//	+ { 8'h0, proc_flags_in[pkg_pflags::pf_slot_c] };
				{out.flags_out[pkg_cpu::FlagC], out.out} = {1'b0, in.a_in} 
					+ {1'b0, (~in.b_in)} 
					+ {`CPU_WORD_WIDTH'b0, in.flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Rsb:
			begin
				{out.flags_out[pkg_cpu::FlagC], out.out} = {1'b0, in.b_in} 
					+ {1'b0, (~in.a_in)} 
					+ {`CPU_WORD_WIDTH'b0, 1'b1};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Mul:
			begin
				out.out = in.a_in * in.b_in;
				out.flags_out = in.flags_in;
			end
			pkg_cpu::Alu_And:
			begin
				out.out = in.a_in & in.b_in;
				{out.flags_out[pkg_cpu::FlagV], 
					out.flags_out[pkg_cpu::FlagC]}
					= {in.flags_in[pkg_cpu::FlagV], 
					in.flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
			end
			pkg_cpu::Alu_Or:
			begin
				out.out = in.a_in | in.b_in;
				{out.flags_out[pkg_cpu::FlagV], 
					out.flags_out[pkg_cpu::FlagC]}
					= {in.flags_in[pkg_cpu::FlagV], 
					in.flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
			end
			pkg_cpu::Alu_Xor:
			begin
				out.out = in.a_in ^ in.b_in;
				{out.flags_out[pkg_cpu::FlagV], 
					out.flags_out[pkg_cpu::FlagC]}
					= {in.flags_in[pkg_cpu::FlagV], 
					in.flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
			end
			pkg_cpu::Alu_Lsl:
			begin
				out.out = in.a_in << in.b_in;
				out.flags_out = in.flags_in;
			end
			pkg_cpu::Alu_Lsr:
			begin
				out.out = in.a_in >> in.b_in;
				out.flags_out = in.flags_in;
			end
			pkg_cpu::Alu_Asr:
			begin
				out.out = $signed(in.a_in >>> in.b_in);
				out.flags_out = in.flags_in;
			end
			pkg_cpu::Alu_Rol:
			begin
				//rot_p_temp[(`alu_inout_pair_width 
				//- (b_in_lo & rot_p_mod_thing)) 
				//+: `alu_inout_pair_width]
				out.out = __rot_temp[(`CPU_WORD_WIDTH 
					- (in.b_in & __rot_mod_thing)) 
					+: `CPU_WORD_WIDTH];
				out.flags_out = in.flags_in;
			end
			pkg_cpu::Alu_Ror:
			begin
				//rot_p_temp[(b_in_lo & rot_p_mod_thing) 
				//+: `alu_inout_pair_width]
				out.out = __rot_temp[(in.b_in & __rot_mod_thing) 
					+: `CPU_WORD_WIDTH];
				out.flags_out = in.flags_in;
			end

			pkg_cpu::Alu_Rlc:
			begin
				//{ proc_flags_out[pkg_pflags::pf_slot_c], 
				//	{ out_hi, out_lo } } = { { a_in_hi, a_in_lo }, 
				//	proc_flags_in[pkg_pflags::pf_slot_c] };

				{out.flags_out[pkg_cpu::FlagC], out.out}
					= {in.b_in, in.flags_in[pkg_cpu::FlagC]};
				{out.flags_out[pkg_cpu::FlagN], 
					out.flags_out[pkg_cpu::FlagV],
					out.flags_out[pkg_cpu::FlagZ]}
					= {in.flags_in[pkg_cpu::FlagN], 
					in.flags_in[pkg_cpu::FlagV],
					in.flags_in[pkg_cpu::FlagZ]};
			end

			pkg_cpu::Alu_Rrc:
			begin
				//{ { out_hi, out_lo }, 
				//	proc_flags_out[pkg_pflags::pf_slot_c] }
				//	= { proc_flags_in[pkg_pflags::pf_slot_c],
				//	{ a_in_hi, a_in_lo } };
				//proc_flags_out[pkg_pflags::pf_slot_c] }
				{out.out, out.flags_out[pkg_cpu::FlagC]}
					= {in.flags_in[pkg_cpu::FlagC], in.b_in};

				{out.flags_out[pkg_cpu::FlagN], 
					out.flags_out[pkg_cpu::FlagV],
					out.flags_out[pkg_cpu::FlagZ]}
					= {in.flags_in[pkg_cpu::FlagN], 
					in.flags_in[pkg_cpu::FlagV],
					in.flags_in[pkg_cpu::FlagZ]};
			end



			//default:
			//begin
			//	$display("Alu:  Eek!\n");
			//	$finish;
			//end
		endcase
	end

endmodule

module SmallAlu(input pkg_cpu::StrcInSmallAlu in,
	output pkg_cpu::StrcOutSmallAlu out);

	// Package imports
	import pkg_cpu::*;


	//always_comb // your hair
	always @ (*)
	begin
		case (in.oper)
			// Used mainly for ldst rA, [rB, rC, simm12]
			pkg_cpu::SmallAlu_AddThree:
			begin
				out.out = in.a_in + in.b_in + in.c_in;
			end

			// Fused multiply-add
			pkg_cpu::SmallAlu_Fma:
			begin
				out.out = in.a_in + (in.b_in * in.c_in);
			end
		endcase
	end
endmodule
