`timescale 1ns / 1ps
module sccb_slave (
	input wire i_sioc
	input wire i_rst,
	inout wire i_siod
);

	always @(posedge i_sioc or posedge i_rst) begin
		if (i_rst) begin
			bit_cnt_q <= 7;
			byte_cnt_q <= 0;
		end else if (bit_cnt_q == 0)
			