`include "src/cpu_defines.svinc"



// Simulation top level module
module TopLevel;

	bit __master_clk, __half_clk;

	wire __alu_tester_enable;


	assign __alu_tester_enable = 1;


	initial
	begin
		__master_clk = 0;
		__half_clk = 0;


		//#400
		//$finish;
	end


	always
	begin
		`MASTER_CLOCK_DELAY
		__master_clk = !__master_clk;
	end

	always
	begin
		`HALF_CLOCK_DELAY
		__half_clk = !__half_clk;
	end

	AluTester alu_tester(.clk(__master_clk), .enable(__alu_tester_enable));


endmodule
