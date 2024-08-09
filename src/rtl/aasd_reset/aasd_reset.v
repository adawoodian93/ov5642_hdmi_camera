`timescale 1ns / 1ps
module aasd_reset (
	input wire i_clk,
	input wire i_async_rst,
	output wire o_sync_rst
);

	reg sync_ff_q, sync_ff_2q;

	always @(posedge i_clk or posedge i_async_rst) begin
		if (i_async_rst) begin
			sync_ff_q <= 1'b1;
			sync_ff_2q <= 1'b1;
		end else begin
			sync_ff_q <= 1'b0;
			sync_ff_2q <= sync_ff_q;
		end
	end
	
	assign o_sync_rst = sync_ff_2q;
	
endmodule

