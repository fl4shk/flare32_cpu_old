`include "src/misc_defines.svinc"


`define TEST_RAM_ADDR_WIDTH 32
`define TEST_RAM_ADDR_MSB_POS `WIDTH_TO_MSB_POS(`TEST_RAM_ADDR_WIDTH)

`define TEST_RAM_REAL_ADDR_WIDTH 8
`define TEST_RAM_REAL_ADDR_MSB_POS \
	`WIDTH_TO_MSB_POS(`TEST_RAM_REAL_ADDR_WIDTH)


`define TEST_RAM_DATA_BUS_WIDTH 48
`define TEST_RAM_DATA_BUS_MSB_POS \
	`WIDTH_TO_MSB_POS(`TEST_RAM_DATA_BUS_WIDTH)


// For testing instruction decoding
module TestRam(input bit clk, enable,
	input bit [`TEST_RAM_ADDR_MSB_POS:0] addr_in,
	output bit [`TEST_RAM_DATA_BUS_MSB_POS:0] data_out);


	bit [7:0] __mem[0:`TEST_RAM_REAL_ADDR_MSB_POS];

	initial $readmemh(__mem, "readmemh_input.txt.ignore");

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
