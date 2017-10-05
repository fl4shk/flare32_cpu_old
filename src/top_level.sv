`include "src/misc_defines.svinc"


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



	//always @ (posedge __master_clk)
	//begin
	//	//$display("__master_clk has ticked!");

	//	//case (__half_clk)
	//	//	1'b0:
	//	//	begin
	//	//		$display("__half_clk is low!");
	//	//	end

	//	//	1'b1:
	//	//	begin
	//	//		$display("__half_clk is high!");
	//	//	end
	//	//endcase
	//end


endmodule
