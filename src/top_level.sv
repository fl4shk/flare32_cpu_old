`include "src/cpu_defines.svinc"



// Simulation top level module
module TopLevel;

	bit __master_clk, __half_clk;

	wire __testers_enable;


	assign __testers_enable = 1;


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

	//CompareTester cmp_tester(.clk(__master_clk), 
	//	.enable(__testers_enable));

	RotateTester rotate_tester(.clk(__master_clk),
		.enable(__testers_enable));


endmodule
