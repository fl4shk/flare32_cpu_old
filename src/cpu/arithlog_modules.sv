`include "src/cpu/cpu_defines.svinc"



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
	assign __rot_temp = {in.a, in.a};

	// This task is used by both adding and subtracting to update the V
	// flag.
	task update_v_flag;
		//input some_a_in_msb, some_b_in_msb, some_result_in_msb;
		//output some_proc_flag_v_out;
		//
		//some_proc_flag_v_out = ((some_a_in_msb ^ some_b_in_msb)
		//	& (some_a_in_msb ^ some_result_in_msb));
		//out.flags[pkg_cpu::FlagV]
		//	= !((in.a[`CPU_WORD_MSB_POS] ^ in.b[`CPU_WORD_MSB_POS])
		//	& (in.a[`CPU_WORD_MSB_POS] ^ out.out[`CPU_WORD_MSB_POS]));

		out.flags[pkg_cpu::FlagV]
			= ((in.a[`CPU_WORD_MSB_POS] ^ in.b[`CPU_WORD_MSB_POS])
			& (in.a[`CPU_WORD_MSB_POS] ^ out.out[`CPU_WORD_MSB_POS]));
		//out.flags[pkg_cpu::FlagV]
		//	= ((in.a[`CPU_WORD_MSB_POS] ^ out.out[`CPU_WORD_MSB_POS])
		//	& (in.b[`CPU_WORD_MSB_POS] ^ out.out[`CPU_WORD_MSB_POS]));
	endtask
	task update_n_and_z_flags;
		{out.flags[pkg_cpu::FlagN], out.flags[pkg_cpu::FlagZ]}
			= {out.out[`CPU_WORD_MSB_POS], (out.out == 0)};
	endtask

	//always_comb // your hair
	always @ (*)
	begin
		case (in.oper)
			pkg_cpu::Alu_Add:
			begin
				{out.flags[pkg_cpu::FlagC], out.out} = {1'b0, in.a} 
					+ {1'b0, in.b};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Adc:
			begin
				{out.flags[pkg_cpu::FlagC], out.out} = {1'b0, in.a} 
					+ {1'b0, in.b}
					+ {`CPU_WORD_WIDTH'b0, in.flags[pkg_cpu::FlagC]};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Sub:
			begin
				{out.flags[pkg_cpu::FlagC], out.out} = {1'b0, in.a} 
					+ {1'b0, (~in.b)} 
					+ {`CPU_WORD_WIDTH'b0, 1'b1};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Sbc:
			begin
				//{ proc_flags_out[pkg_pflags::pf_slot_c], out_lo } 
				//	= { 1'b0, a_in_lo } + { 1'b0, (~b_in_lo) } 
				//	+ { 8'h0, proc_flags_in[pkg_pflags::pf_slot_c] };
				{out.flags[pkg_cpu::FlagC], out.out} = {1'b0, in.a} 
					+ {1'b0, (~in.b)} 
					+ {`CPU_WORD_WIDTH'b0, in.flags[pkg_cpu::FlagC]};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Rsb:
			begin
				{out.flags[pkg_cpu::FlagC], out.out} = {1'b0, in.b} 
					+ {1'b0, (~in.a)} 
					+ {`CPU_WORD_WIDTH'b0, 1'b1};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Mul:
			begin
				out.out = in.a * in.b;
				out.flags = in.flags;
			end
			pkg_cpu::Alu_And:
			begin
				out.out = in.a & in.b;
				{out.flags[pkg_cpu::FlagV], 
					out.flags[pkg_cpu::FlagC]}
					= {in.flags[pkg_cpu::FlagV], 
					in.flags[pkg_cpu::FlagC]};
				update_n_and_z_flags();
			end
			pkg_cpu::Alu_Or:
			begin
				out.out = in.a | in.b;
				{out.flags[pkg_cpu::FlagV], 
					out.flags[pkg_cpu::FlagC]}
					= {in.flags[pkg_cpu::FlagV], 
					in.flags[pkg_cpu::FlagC]};
				update_n_and_z_flags();
			end
			pkg_cpu::Alu_Xor:
			begin
				out.out = in.a ^ in.b;
				{out.flags[pkg_cpu::FlagV], 
					out.flags[pkg_cpu::FlagC]}
					= {in.flags[pkg_cpu::FlagV], 
					in.flags[pkg_cpu::FlagC]};
				update_n_and_z_flags();
			end
			pkg_cpu::Alu_Lsl:
			begin
				out.out = in.a << in.b;
				out.flags = in.flags;
			end
			pkg_cpu::Alu_Lsr:
			begin
				out.out = in.a >> in.b;
				out.flags = in.flags;
			end
			pkg_cpu::Alu_Asr:
			begin
				out.out = $signed(in.a >>> in.b);
				out.flags = in.flags;
			end
			pkg_cpu::Alu_Rol:
			begin
				//rot_p_temp[(`alu_inout_pair_width 
				//- (b_in_lo & rot_p_mod_thing)) 
				//+: `alu_inout_pair_width]
				out.out = __rot_temp[(`CPU_WORD_WIDTH 
					- (in.b & __rot_mod_thing)) 
					+: `CPU_WORD_WIDTH];
				out.flags = in.flags;
			end
			pkg_cpu::Alu_Ror:
			begin
				//rot_p_temp[(b_in_lo & rot_p_mod_thing) 
				//+: `alu_inout_pair_width]
				out.out = __rot_temp[(in.b & __rot_mod_thing) 
					+: `CPU_WORD_WIDTH];
				out.flags = in.flags;
			end

			pkg_cpu::Alu_Rlc:
			begin
				//{ proc_flags_out[pkg_pflags::pf_slot_c], 
				//	{ out_hi, out_lo } } = { { a_in_hi, a_in_lo }, 
				//	proc_flags_in[pkg_pflags::pf_slot_c] };

				{out.flags[pkg_cpu::FlagC], out.out}
					= {in.b, in.flags[pkg_cpu::FlagC]};
				{out.flags[pkg_cpu::FlagN], 
					out.flags[pkg_cpu::FlagV],
					out.flags[pkg_cpu::FlagZ]}
					= {in.flags[pkg_cpu::FlagN], 
					in.flags[pkg_cpu::FlagV],
					in.flags[pkg_cpu::FlagZ]};
			end

			pkg_cpu::Alu_Rrc:
			begin
				//{ { out_hi, out_lo }, 
				//	proc_flags_out[pkg_pflags::pf_slot_c] }
				//	= { proc_flags_in[pkg_pflags::pf_slot_c],
				//	{ a_in_hi, a_in_lo } };
				//proc_flags_out[pkg_pflags::pf_slot_c] }
				{out.out, out.flags[pkg_cpu::FlagC]}
					= {in.flags[pkg_cpu::FlagC], in.b};

				{out.flags[pkg_cpu::FlagN], 
					out.flags[pkg_cpu::FlagV],
					out.flags[pkg_cpu::FlagZ]}
					= {in.flags[pkg_cpu::FlagN], 
					in.flags[pkg_cpu::FlagV],
					in.flags[pkg_cpu::FlagZ]};
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
				out.out = in.a + in.b + in.c;
			end

			// Fused multiply-add
			pkg_cpu::SmallAlu_Fma:
			begin
				out.out = in.a + (in.b * in.c);
			end
		endcase
	end
endmodule


module SignExtender16(input wire [`CPU_WORD_MSB_POS:0] in,
	output wire [`CPU_WORD_MSB_POS:0] out);

	assign out = (in[15]) ? {16'hffff, in[15:0]} : {16'h0000, in[15:0]};
endmodule

module SignExtender8(input wire [`CPU_WORD_MSB_POS:0] in,
	output wire [`CPU_WORD_MSB_POS:0] out);

	assign out = (in[7]) 
		? {24'hff_ffff, in[7:0]} 
		: {24'h00_0000, in[7:0]};
endmodule

module PlainAdder(input wire [`CPU_WORD_MSB_POS:0] a, b,
	output wire [`CPU_WORD_MSB_POS:0] out);

	assign out = a + b;
endmodule
module PlainAddThree(input wire [`CPU_WORD_MSB_POS:0] a, b, c,
	output wire [`CPU_WORD_MSB_POS:0] out);

	assign out = a + b + c;
endmodule
module PlainSubtractor(input wire [`CPU_WORD_MSB_POS:0] a, b,
	output wire [`CPU_WORD_MSB_POS:0] out);

	assign out = a - b;
endmodule



module LongLsl
	(input wire [pkg_cpu::long_arithlog_operand_msb_pos:0] a, b,
	output wire [pkg_cpu::long_arithlog_operand_msb_pos:0] out);

	import pkg_cpu::*;

	assign out = a << b;
endmodule

module LongLsr
	(input wire [pkg_cpu::long_arithlog_operand_msb_pos:0] a, b,
	output wire [pkg_cpu::long_arithlog_operand_msb_pos:0] out);

	import pkg_cpu::*;

	assign out = a >> b;
endmodule

module LongAsr
	(input wire [pkg_cpu::long_arithlog_operand_msb_pos:0] a, b,
	output wire [pkg_cpu::long_arithlog_operand_msb_pos:0] out);

	import pkg_cpu::*;

	assign out = $signed(a >>> b);
endmodule


module LongUMul(input wire [`CPU_WORD_MSB_POS:0] a, b,
	output wire [pkg_cpu::long_arithlog_operand_msb_pos:0] out);

	import pkg_cpu::*;

	assign out = a * b;
endmodule

module LongSMul(input wire [`CPU_WORD_MSB_POS:0] a, b,
	output wire [pkg_cpu::long_arithlog_operand_msb_pos:0] out);

	import pkg_cpu::*;

	assign out = $signed(a) * $signed(b);
endmodule
