`include "src/cpu_defines.svinc"





//// For testing instruction decoding
//module ReadOnlyRam(input bit clk, enable,
//	input bit [`CPU_ADDR_BUS_MSB_POS:0] addr_in,
//	output bit [`CPU_DATA_BUS_MAX_MSB_POS:0] data_out);
//
//
//	// Package imports
//	import pkg_testing::*;
//
//	bit [7:0] __mem[0:test_ram_mem_max_offset];
//
//	initial $readmemh("readmemh_input.txt.ignore", __mem);
//
//	always @ (posedge clk)
//	begin
//		if (enable)
//		begin
//			data_out <= {__mem[addr_in & 8'hff],
//				__mem[(addr_in + 1) & 8'hff],
//
//				__mem[(addr_in + 2) & 8'hff],
//				__mem[(addr_in + 3) & 8'hff],
//
//				__mem[(addr_in + 4) & 8'hff],
//				__mem[(addr_in + 5) & 8'hff]};
//		end
//	end
//
//
//endmodule


module AluTester(input bit clk);

	import pkg_cpu::*;

	pkg_cpu::StrcInAlu alu_in;
	pkg_cpu::StrcOutAlu alu_out;
	
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

	task exec_alu;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;
		input [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] some_oper;
		input [`CPU_ENUM_FLAGS_POS_MSB_POS:0] some_flags_in;

		init_alu(some_a, some_b, some_oper, some_flags_in);

		`MASTER_CLOCK_DELAY
		$display("%h %h %d %b\t\t%h %b",
			alu_in.a_in, alu_in.b_in, alu_in.oper, alu_in.flags_in,
			alu_out.out, alu_out.flags_out);
	endtask


	//initial
	//begin
	//	#400
	//	$finish;
	//end

	initial
	begin
		exec_alu(-1, 50, pkg_cpu::Alu_Add, 4'b0000);
		exec_alu(-1, 50, pkg_cpu::Alu_Add, 4'b0001);
		exec_alu(-1, 50, pkg_cpu::Alu_Adc, 4'b0000);
		exec_alu(-1, 50, pkg_cpu::Alu_Adc, 4'b0001);
		$display();

		exec_alu(50, -1, pkg_cpu::Alu_Add, 4'b0000);
		exec_alu(50, -1, pkg_cpu::Alu_Add, 4'b0001);
		exec_alu(50, -1, pkg_cpu::Alu_Adc, 4'b0000);
		exec_alu(50, -1, pkg_cpu::Alu_Adc, 4'b0001);
		$display();

		exec_alu(-1, 50, pkg_cpu::Alu_Sub, 4'b0000);
		exec_alu(-1, 50, pkg_cpu::Alu_Sub, 4'b0001);
		exec_alu(-1, 50, pkg_cpu::Alu_Sbc, 4'b0000);
		exec_alu(-1, 50, pkg_cpu::Alu_Sbc, 4'b0001);
		$display();

		exec_alu(50, -1, pkg_cpu::Alu_Sub, 4'b0000);
		exec_alu(50, -1, pkg_cpu::Alu_Sub, 4'b0001);
		exec_alu(50, -1, pkg_cpu::Alu_Sbc, 4'b0000);
		exec_alu(50, -1, pkg_cpu::Alu_Sbc, 4'b0001);
		$display();


		$finish;
	end

	Alu alu(.in(alu_in), .out(alu_out));


endmodule
