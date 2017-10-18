`include "src/cpu_defines.svinc"



module Alu(input bit [`CPU_WORD_MSB_POS:0] a, b, c,
	input bit [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] oper,
	input bit [`CPU_FLAGS_MSB_POS:0] flags_in,

	output bit [`CPU_WORD_MSB_POS:0] out,
	output bit [`CPU_FLAGS_MSB_POS:0] flags_out);



	// Package imports
	import pkg_cpu::*;


	// This task is used by both adding and subtracting to update the V
	// flag.
	task update_v_flag;
		//input some_a_in_msb, some_b_in_msb, some_result_in_msb;
		//output some_proc_flag_v_out;
		//
		//some_proc_flag_v_out = ((some_a_in_msb ^ some_b_in_msb)
		//	& (some_a_in_msb ^ some_result_in_msb));
		flags_out[pkg_cpu::FlagV]
			= ((a[`CPU_WORD_MSB_POS] ^ b[`CPU_WORD_MSB_POS])
			& (a[`CPU_WORD_MSB_POS] ^ out[`CPU_WORD_MSB_POS]));
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
				{flags_out[pkg_cpu::FlagC], out} = {1'b0, a} + {1'b0, b};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Adc:
			begin
				{flags_out[pkg_cpu::FlagC], out} = {1'b0, a} + {1'b0, b}
					+ {`CPU_WORD_WIDTH'b0, flags_in[pkg_cpu::FlagC]};
				update_n_and_z_flags();
				update_v_flag();
			end
			pkg_cpu::Alu_Sub:
			begin
				
			end
			pkg_cpu::Alu_Sbc:
			begin
				
			end
			pkg_cpu::Alu_Rsb:
			begin
				
			end
			pkg_cpu::Alu_Mul:
			begin
				
			end
			pkg_cpu::Alu_And:
			begin
				
			end
			pkg_cpu::Alu_Or:
			begin
				
			end
			pkg_cpu::Alu_Xor:
			begin
				
			end
			pkg_cpu::Alu_Lsl:
			begin
				flags_out = flags_in;
			end
			pkg_cpu::Alu_Lsr:
			begin
				flags_out = flags_in;
			end
			pkg_cpu::Alu_Asr:
			begin
				flags_out = flags_in;
			end
			pkg_cpu::Alu_Rol:
			begin
				flags_out = flags_in;
			end
			pkg_cpu::Alu_Ror:
			begin
				flags_out = flags_in;
			end

			pkg_cpu::Alu_Rlc:
			begin
				
			end

			pkg_cpu::Alu_Rrc:
			begin
				
			end


			// Used mainly for ldst rA, [rB, rC, simm12]
			pkg_cpu::Alu_AddThree:
			begin
				flags_out = flags_in;
			end

			// Fused multiply-add
			pkg_cpu::Alu_Fma:
			begin
				out = a + (b * c);
				flags_out = flags_in;
			end
		endcase
	end

endmodule
