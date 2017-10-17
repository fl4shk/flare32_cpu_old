`include "src/misc_defines.svinc"
`include "src/cpu_defines.svinc"






// For testing instruction decoding
module TestRam(input bit clk, enable,
	input bit [`CPU_ADDR_BUS_MSB_POS:0] addr_in,
	output bit [`CPU_DATA_BUS_MAX_MSB_POS:0] data_out);


	// Package imports
	import pkg_testing::*;

	bit [7:0] __mem[0:test_ram_mem_max_offset];

	initial $readmemh("readmemh_input.txt.ignore", __mem);

	always @ (posedge clk)
	begin
		if (enable)
		begin
			data_out <= {__mem[addr_in & 8'hff],
				__mem[(addr_in + 1) & 8'hff],

				__mem[(addr_in + 2) & 8'hff],
				__mem[(addr_in + 3) & 8'hff],

				__mem[(addr_in + 4) & 8'hff],
				__mem[(addr_in + 5) & 8'hff]};
		end
	end


endmodule


// Simulation top level module
module TopLevel;

	bit __master_clk, __half_clk;


	initial
	begin
		__master_clk = 0;
		__half_clk = 0;


		#400
		$finish;
	end


	always
	begin
		`MASTER_CLOCK_DELAY
		__master_clk = !__master_clk;
	end

	always
	begin
		`MASTER_CLOCK_DELAY
		`MASTER_CLOCK_DELAY
		__half_clk = !__half_clk;
	end



endmodule
