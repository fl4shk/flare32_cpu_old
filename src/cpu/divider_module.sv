`include "src/cpu/misc_defines.svinc"

// Unsigned (or signed!) integer division
// Don't try to do larger than a 128-bit division with this without
// increasing counter_msb_pos.

// Depending on the FPGA being used and the clock rate, it may be doable to
// perform more than one iterate() per cycle, obtaining faster divisions.

// For obvious reasons, this does not return a correct result upon division
// by zero.

module NonRestoringDivider #(parameter args_width=32)
	(input wire clk, enable, unsgn_or_sgn,
	// Numerator, Denominator
	input bit [`WIDTH_TO_MSB_POS(args_width):0] num, denom,

	// Quotient, Remainder
	output bit [`WIDTH_TO_MSB_POS(args_width):0] quot, rem,

	output bit can_accept_cmd, data_ready);


	parameter args_msb_pos = `WIDTH_TO_MSB_POS(args_width);


	parameter temp_width = (args_width << 1) + 1;

	parameter temp_msb_pos = `WIDTH_TO_MSB_POS(temp_width);


	// This assumes you aren't trying to do division of numbers larger than
	// 128-bit.
	parameter counter_msb_pos = 7;




	bit [counter_msb_pos:0] __counter, __state_counter;

	bit [args_msb_pos:0] __num_buf, __denom_buf;
	bit [args_msb_pos:0] __quot_buf, __rem_buf;


	wire __busy;
	wire __num_is_negative, __denom_is_negative;
	bit __num_was_negative, __denom_was_negative;
	bit __unsgn_or_sgn_buf;



	// Temporaries
	bit [temp_msb_pos:0] __P;
	bit [temp_msb_pos:0] __D;



	// Tasks
	task iterate;
		// if (__P >= 0)
		if (!__P[temp_msb_pos] || (__P == 0))
		begin
			__quot_buf[__counter] = 1;
			__P = (__P << 1) - __D;
		end

		else
		begin
			__quot_buf[__counter] = 0;
			__P = (__P << 1) + __D;
		end

		__counter = __counter - 1;
	endtask



	// Assignments
	assign __busy = !can_accept_cmd;

	assign __num_is_negative = $signed(num) < $signed(0);
	assign __denom_is_negative = $signed(denom) < $signed(0);



	initial
	begin
		__counter = 0;
		__state_counter = 0;
		__P = 0;
		__D = 0;

		__state_counter = 0;

		quot = 0;
		rem = 0;

		can_accept_cmd = 1;
		data_ready = 0;
	end


	always @ (posedge clk)
	begin
		if (__state_counter[counter_msb_pos])
		begin
			__quot_buf = 0;
			__rem_buf = 0;

			__counter = args_msb_pos;


			__P = __num_buf;
			__D = __denom_buf << args_width;
		end

		else if (__busy)
		begin
			//if (!__state_counter[counter_msb_pos])
			if ($signed(__counter) > $signed(-1))
			begin
				// At some clock rates, some FPGAs may be able to handle
				// more than one iteration per clock cycle, which is why
				// iterate() is a task.  Feel free to try more than one
				// iteration per clock cycle.

				iterate();
				iterate();
			end
		end

	end


	always @ (posedge clk)
	begin
		if (enable && can_accept_cmd)
		begin
			can_accept_cmd <= 0;
			data_ready <= 0;
			__state_counter <= -1;


			__num_buf <= (unsgn_or_sgn && __num_is_negative)
				? (-num) : num;
			__denom_buf <= (unsgn_or_sgn && __denom_is_negative)
				? (-denom) : denom;

			__unsgn_or_sgn_buf <= unsgn_or_sgn;

			__num_was_negative <= __num_is_negative;
			__denom_was_negative <= __denom_is_negative;
		end

		else if (__busy)
		begin
			if (!__counter[counter_msb_pos])
			begin
				__state_counter <= __state_counter + 1;
			end

			else
			begin
				can_accept_cmd <= 1;
				__state_counter <= -1;
				data_ready <= 1;

				//$display("end:  %d, %d %d, %d",
				//	__unsgn_or_sgn_buf, 
				//	__num_was_negative, __denom_was_negative,
				//	(__num_was_negative ^ __denom_was_negative));
				if (__P[temp_msb_pos])
				begin
					quot <= (__unsgn_or_sgn_buf 
						&& (__num_was_negative  ^ __denom_was_negative))
						?  (-((__quot_buf - (~__quot_buf)) - 1))
						: ((__quot_buf - (~__quot_buf)) - 1);
					rem <= (__unsgn_or_sgn_buf && __num_was_negative)
						? (-((__P + __D) >> args_width))
						: ((__P + __D) >> args_width);
				end

				else
				begin
					quot <= (__unsgn_or_sgn_buf
						&& (__num_was_negative ^ __denom_was_negative))
						? (-((__quot_buf - (~__quot_buf))))
						: ((__quot_buf - (~__quot_buf)));
					rem <= (__unsgn_or_sgn_buf && __num_was_negative)
						? (-((__P) >> args_width))
						: ((__P) >> args_width);
				end
			end
		end
	end


endmodule
