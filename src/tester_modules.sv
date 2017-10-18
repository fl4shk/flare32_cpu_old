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


module CompareTester(input bit clk, enable);

	import pkg_cpu::*;

	pkg_cpu::StrcInAlu alu_in;
	pkg_cpu::StrcOutAlu alu_out;

	bit [`CPU_WORD_MSB_POS:0] tester_a, tester_b;

	longint i, j;
	
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

	task display_alu_unsigned;
		$display("%h %h %d %b\t\t%h %b",
			alu_in.a_in, alu_in.b_in, alu_in.oper, alu_in.flags_in,
			alu_out.out, alu_out.flags_out);
	endtask
	task display_alu_signed;
		$display("%d %d %d %b\t\t%d %b\t\t%b",
			$signed(alu_in.a_in), $signed(alu_in.b_in), 
			alu_in.oper, alu_in.flags_in,
			$signed(alu_out.out), alu_out.flags_out,
			
			(alu_out.flags_out[pkg_cpu::FlagN] 
			== alu_out.flags_out[pkg_cpu::FlagV]) );
	endtask

	task exec_alu_and_display_unsigned;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;
		input [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] some_oper;
		input [`CPU_ENUM_FLAGS_POS_MSB_POS:0] some_flags_in;

		init_alu(some_a, some_b, some_oper, some_flags_in);

		`MASTER_CLOCK_DELAY
		display_alu_unsigned();
	endtask


	task test_eq_ne_compare;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;

		init_alu(some_a, some_b, pkg_cpu::Alu_Sub, 4'b0000);

		`MASTER_CLOCK_DELAY

		// Z == 0
		if (some_a != some_b)
		begin
			if (!(alu_out.flags_out[pkg_cpu::FlagZ] == 0))
			begin
				$display("!= Error with");
				display_alu_unsigned();
			end
		end

		// Z == 1
		if (some_a == some_b)
		begin
			if (!(alu_out.flags_out[pkg_cpu::FlagZ] == 1))
			begin
				$display("== Error with");
				display_alu_unsigned();
			end
		end
	endtask


	task test_unsigned_compare;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;

		init_alu(some_a, some_b, pkg_cpu::Alu_Sub, 4'b0000);

		`MASTER_CLOCK_DELAY

		// C == 0 [unsigned less than]
		if (some_a < some_b)
		begin
			if (!(alu_out.flags_out[pkg_cpu::FlagC] == 0))
			begin
				$display("< Error with");
				display_alu_unsigned();
			end
		end

		// (C == 0 or Z == 1) [unsigned less than or equal]
		if (some_a <= some_b)
		begin
			if (!((alu_out.flags_out[pkg_cpu::FlagC] == 0)
				|| (alu_out.flags_out[pkg_cpu::FlagZ] == 1)))
			begin
				$display("<= Error with");
				display_alu_unsigned();
			end
		end

		// (C == 1 and Z == 0) [unsigned greater than]
		if (some_a > some_b)
		begin
			if (!((alu_out.flags_out[pkg_cpu::FlagC] == 1)
				&& (alu_out.flags_out[pkg_cpu::FlagZ] == 0)))
			begin
				$display("> Error with");
				display_alu_unsigned();
			end
		end

		// C == 1 [unsigned greater than or equal]
		if (some_a >= some_b)
		begin
			if (!(alu_out.flags_out[pkg_cpu::FlagC] == 1))
			begin
				$display(">= Error with");
				display_alu_unsigned();
			end
		end
	
	
	endtask

	task test_signed_compare;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;

		init_alu(some_a, some_b, pkg_cpu::Alu_Sub, 4'b0000);

		`MASTER_CLOCK_DELAY


		// N != V [signed less than]
		if ($signed(some_a) < $signed(some_b))
		begin
			if (!(alu_out.flags_out[pkg_cpu::FlagN]
				!= alu_out.flags_out[pkg_cpu::FlagV]))
			begin
				$display("Signed < Error with");
				display_alu_signed();
			end
		end

		// (N != V or Z == 1) [signed less than or equal]
		if ($signed(some_a) <= $signed(some_b))
		begin
			if (!((alu_out.flags_out[pkg_cpu::FlagN]
				!= alu_out.flags_out[pkg_cpu::FlagV])
				|| (alu_out.flags_out[pkg_cpu::FlagZ] == 1)))
			begin
				$display("Signed <= Error with");
				display_alu_signed();
			end
		end

		// (N == V and Z == 0) [signed greater than]
		if ($signed(some_a) > $signed(some_b))
		begin
			if (!((alu_out.flags_out[pkg_cpu::FlagN]
				== alu_out.flags_out[pkg_cpu::FlagV])
				&& (alu_out.flags_out[pkg_cpu::FlagZ] == 0)))
			begin
				$display("Signed > Error with");
				display_alu_signed();
			end
		end

		// N == V [signed greater than or equal]
		if ($signed(some_a) >= $signed(some_b))
		begin
			if (!(alu_out.flags_out[pkg_cpu::FlagN]
				== alu_out.flags_out[pkg_cpu::FlagV]))
			begin
				$display("Signed >= Error with");
				display_alu_signed();
			end
		end
	
	
	endtask



	initial
	begin
		if (enable)
		begin
			for (i=0; i<`WIDTH_TO_SIZE(`CPU_WORD_WIDTH); i=i+1)
			begin
				for (j=0; j<`WIDTH_TO_SIZE(`CPU_WORD_WIDTH); j=j+1)
				begin
					tester_a = i;
					tester_b = j;
					test_eq_ne_compare(tester_a, tester_b);
					test_unsigned_compare(tester_a, tester_b);
					test_signed_compare(tester_a, tester_b);
				end
			end
			$finish;
		end
	end


	Alu alu(.in(alu_in), .out(alu_out));


endmodule


module RotateTester(input bit clk, enable);

	import pkg_cpu::*;

	pkg_cpu::StrcInAlu alu_in;
	pkg_cpu::StrcOutAlu alu_out;

	bit [`CPU_WORD_MSB_POS:0] tester_a, tester_b;

	bit [`CPU_WORD_MSB_POS:0] tester_rol_out, tester_ror_out;
	bit [`CPU_WORD_WIDTH:0] tester_rlc_out, tester_rrc_out;
	bit tester_carry_in;

	longint i, j;



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

	task display_alu_unsigned;
		$display("%h %h %d %b\t\t%h %b",
			alu_in.a_in, alu_in.b_in, alu_in.oper, alu_in.flags_in,
			alu_out.out, alu_out.flags_out);
	endtask
	task display_alu_signed;
		$display("%d %d %d %b\t\t%d %b\t\t%b",
			$signed(alu_in.a_in), $signed(alu_in.b_in), 
			alu_in.oper, alu_in.flags_in,
			$signed(alu_out.out), alu_out.flags_out,
			
			(alu_out.flags_out[pkg_cpu::FlagN] 
			== alu_out.flags_out[pkg_cpu::FlagV]) );
	endtask

	task exec_alu_and_display_unsigned;
		input [`CPU_WORD_MSB_POS:0] some_a, some_b;
		input [`CPU_ENUM_ALU_OPER_SIZE_MSB_POS:0] some_oper;
		input [`CPU_ENUM_FLAGS_POS_MSB_POS:0] some_flags_in;

		init_alu(some_a, some_b, some_oper, some_flags_in);

		`MASTER_CLOCK_DELAY
		display_alu_unsigned();
	endtask




	task test_rol;
		input [`CPU_WORD_MSB_POS:0] some_value, some_count;

		init_alu(some_value, some_count, pkg_cpu::Alu_Rol, 4'b0000);

		tester_rol_out = some_count % `CPU_WORD_WIDTH;
		tester_rol_out = (some_value << tester_rol_out) 
			| (some_value >> ((-tester_rol_out) % `CPU_WORD_WIDTH));

		`MASTER_CLOCK_DELAY

		if (tester_rol_out != alu_out.out)
		begin
			$display("%h:  Rol Error with", tester_rol_out);
			display_alu_unsigned();
		end

	endtask

	task test_ror;
		input [`CPU_WORD_MSB_POS:0] some_value, some_count;

		init_alu(some_value, some_count, pkg_cpu::Alu_Ror, 4'b0000);

		tester_ror_out = some_count % `CPU_WORD_WIDTH;
		tester_ror_out = (some_value >> tester_ror_out) 
			| (some_value << ((-tester_ror_out) % `CPU_WORD_WIDTH));

		`MASTER_CLOCK_DELAY

		if (tester_ror_out != alu_out.out)
		begin
			$display("%h:  Ror Error with", tester_ror_out);
			display_alu_unsigned();
		end
	endtask

	//task test_rlc;
	//	input [`CPU_WORD_MSB_POS:0] some_value;
	//	input some_carry_in;

	//	init_alu(`CPU_WORD_WIDTH'd0, some_value, pkg_cpu::Alu_Rlc,
	//		{3'b000, some_carry_in});

	//	tester_rlc_out = 1 % (`CPU_WORD_WIDTH + 1);
	//	tester_rlc_out = ({some_carry_in, some_value} << tester_rlc_out) 
	//		| ({some_carry_in, some_value} 
	//		>> ((-tester_rlc_out) % (`CPU_WORD_WIDTH + 1)));

	//	if (tester_rlc_out 
	//		!= {alu_out.flags_out[pkg_cpu::FlagC], alu_out.out})
	//	begin
	//		$display("%h:  Rlc Error with", tester_rlc_out);
	//		display_alu_unsigned();
	//	end
	//endtask

	//task test_rrc;
	//	input [`CPU_WORD_MSB_POS:0] some_value;
	//	input some_carry_in;

	//	init_alu(`CPU_WORD_WIDTH'd0, some_value, pkg_cpu::Alu_Rrc,
	//		{3'b000, some_carry_in});

	//	tester_rrc_out = 1 % (`CPU_WORD_WIDTH + 1);
	//	tester_rrc_out = ({some_value, some_carry_in} >> tester_rrc_out) 
	//		| ({some_value, some_carry_in} 
	//		<< ((-tester_rrc_out) % (`CPU_WORD_WIDTH + 1)));

	//	if (tester_rrc_out 
	//		!= {alu_out.out, alu_out.flags_out[pkg_cpu::FlagC]})
	//	begin
	//		$display("%h:  Rrc Error with", tester_rrc_out);
	//		display_alu_unsigned();
	//	end
	//endtask


	initial
	begin
		if (enable)
		begin
			for (i=0; i<`WIDTH_TO_SIZE(`CPU_WORD_WIDTH); i=i+1)
			begin
				for (j=0; j<`WIDTH_TO_SIZE(`CPU_WORD_WIDTH); j=j+1)
				begin
					tester_a = i;
					tester_b = j;
					test_rol(tester_a, tester_b);
					test_ror(tester_a, tester_b);
				end
			end

			//for (i=0; i<`WIDTH_TO_SIZE(`CPU_WORD_WIDTH); i=i+1)
			//begin
			//	for (j=0; j<2; j=j+1)
			//	begin
			//		tester_a = i;
			//		tester_carry_in = j;
			//		test_rlc(tester_a, tester_carry_in);
			//		test_rrc(tester_a, tester_carry_in);
			//	end
			//end
			$finish;
		end
	end


	Alu alu(.in(alu_in), .out(alu_out));


endmodule