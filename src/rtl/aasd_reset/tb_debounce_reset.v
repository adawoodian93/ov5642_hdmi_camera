`timescale 1ns / 1ps
module tb_debounce_reset ();

	reg i_clk;
	reg i_pb;
	
	wire        o_pb_clean;
	wire        o_sync_reset;
	wire [16:0] cs_clk_count_q;
	wire        cs_clk_en_q;   
	wire        cs_pb_q3;      
	wire        cs_pb_q2;      
	wire        cs_pb_q1;      
	
	//Clock and reset generation
	initial i_clk = 1'b0;
	always #5 i_clk = !i_clk;
	
	//DUT
	debounce DUT_0 (
		.i_clk         (i_clk         ),
		.i_pb          (i_pb          ),
		.o_pb_clean    (o_pb_clean    ),
		.cs_pb_q1      (cs_pb_q1      ),
		.cs_pb_q2      (cs_pb_q2      ),
		.cs_pb_q3      (cs_pb_q3      ),
		.cs_clk_en_q   (cs_clk_en_q   ),
		.cs_clk_count_q(cs_clk_count_q)
	);
	
	aasd_reset DUT_1 (
		.i_clk(i_clk),
		.i_async_rst(o_pb_clean),
		.o_sync_rst(o_sync_reset)
	);
	
	//Stimuli generation
	initial begin
		i_pb = 0;
		#10 i_pb = 1;
		#20 i_pb = 0;
		#10 i_pb = 1;
		#30 i_pb = 0;
		#10 i_pb = 1;
		#40 i_pb = 0;
		#10 i_pb = 1;
		#30 i_pb = 0;
		#10 i_pb = 1; 
		#1000 i_pb = 0;
		#10 i_pb = 1;
		#20 i_pb = 0;
		#10 i_pb = 1;
		#30 i_pb = 0;
		#10 i_pb = 1;
		#40 i_pb = 0; 
	end

endmodule	