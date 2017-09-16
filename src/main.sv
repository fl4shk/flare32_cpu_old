package pkg_main;

typedef enum bit [7:0]
{
	StInit,

	StQuit
} State;


endpackage


module Main;
	
	import pkg_main::*;


	bit __clk;

	bit [7:0] __state;

	initial
	begin
		__clk = 0;
		__state = pkg_main::StInit;
	end


	always
	begin
		#1
		__clk = !__clk;
	end


	always @ (posedge __clk)
	begin
		case (__state)
			pkg_main::StInit:
			begin
				__state <= pkg_main::StQuit;
				$display("I'm in starting state!");
			end

			pkg_main::StQuit:
			begin
				$display("I'm quitting now!");
				$finish;
			end

		endcase
		
	end



endmodule
