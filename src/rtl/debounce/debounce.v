`timescale 1ns / 1ps
module debounce (
	input wire i_clk,
	input wire i_pb,
	
	output wire o_pb_clean,
	
	// TB Ports
	output wire        cs_pb_q1,      
	output wire        cs_pb_q2,      
	output wire        cs_pb_q3,      
	output wire        cs_clk_en_q,   
	output wire [16:0] cs_clk_count_q
);

	reg        pb_q1 = 1'b0;
	reg        pb_q2 = 1'b0;
	reg        pb_q3 = 1'b0;
	reg        clk_en_q = 1'b0;
	reg [16:0] clk_count_q = 0;

	always @(posedge i_clk) begin
		if (clk_en_q) begin
			pb_q1 <= i_pb; 
			pb_q2 <= pb_q1;
			pb_q3 <= pb_q2;
		end
	end
	
	always @(posedge i_clk) begin
		clk_en_q <= (clk_count_q == 9) ? 1'b1 : 1'b0;
		clk_count_q <= (clk_count_q >= 9) ? 0 : clk_count_q + 1;
	end
	
	assign o_pb_clean = pb_q2 && (!pb_q3);
	
	//TB port assignments
	assign cs_pb_q1       = pb_q1      ;
	assign cs_pb_q2       = pb_q2      ;
	assign cs_pb_q3       = pb_q3      ;
	assign cs_clk_en_q    = clk_en_q   ;
	assign cs_clk_count_q = clk_count_q;
	
endmodule