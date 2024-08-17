//State machine states
`define IDLE                 3'b000
`define ID_ADDRESS           3'b001
`define SUB_ADDRESS_AND_DATA 3'b010
`define RD_DATA              3'b011

`timescale 1ns / 1ps
module sccb_slave #(
	parameter SIOC_FREQ = 100000)
(
	input wire i_clk,
	input wire i_rst,
	input wire i_sioc,
	input wire i_siod_in,
	output reg o_siod_out,
	
	//TB Ports
	output wire       cs_siod_in_q,
	output wire 	     cs_sioc_q,
	output wire [3:0] cs_sioc_hi_cnt_q,
	output wire [3:0] cs_sioc_lo_cnt_q,
	output wire [7:0] cs_id_addr_q,
	output wire [3:0] cs_id_addr_bit_q,
	output wire [3:0] cs_bit_cnt_q,
	output wire [1:0] cs_byte_cnt_q,
	output wire [7:0] cs_wr_data_q,
	output wire [3:0] cs_wr_data_cnt_q,
	output wire [2:0] cs_pstate_q,
	output wire [2:0] cs_nstate,
	output wire 	     cs_siod_fedge,
	output wire 	     cs_siod_redge,
	output wire 	     cs_sioc_redge,
	output wire 	     cs_sioc_lo,
	output wire 	     cs_sioc_hi
);

	localparam SIOC_PERIOD = (100_000_000/(SIOC_FREQ*2));
	localparam SIOC_HALF_PERIOD = ((100_000_000/(SIOC_FREQ*2))/2);
	
	reg       siod_in_q;
	reg       sioc_q;
	reg [3:0] sioc_hi_cnt_q;
	reg [3:0] sioc_lo_cnt_q;
	reg [7:0] id_addr_q;
	reg [3:0] id_addr_bit_q;
	reg [3:0] bit_cnt_q;
	reg [1:0] byte_cnt_q;
	reg [7:0] wr_data_q;
	reg [3:0] wr_data_cnt_q;
	reg [2:0] pstate_q;
	reg [2:0] nstate;
	
	wire      siod_fedge;
	wire      siod_redge;
	wire      sioc_redge;
	wire      sioc_lo;
	wire      sioc_hi;
	
	always @(posedge i_clk) begin
		if (i_rst) begin
			siod_in_q <= 1'b1;
			sioc_q    <= 1'b1;
		end else begin
			siod_in_q <= i_siod_in;
			sioc_q <= i_sioc;
		end
	end
	
	assign siod_fedge = (!i_siod_in) && siod_in_q;
	assign siod_redge = i_siod_in && (!siod_in_q);
	assign sioc_redge = i_sioc && (!sioc_q);
	
	always @(posedge i_clk) begin
		if (i_rst) begin
			sioc_hi_cnt_q <= 0;
			sioc_lo_cnt_q <= 0;
		end else if (i_sioc) begin
			sioc_lo_cnt_q <= 0;
			sioc_hi_cnt_q <= sioc_hi_cnt_q + 1;
		end else if (!i_sioc) begin
			sioc_hi_cnt_q <= 0;
			sioc_lo_cnt_q <= sioc_lo_cnt_q + 1;
		end
	end
	
	assign sioc_lo = (sioc_lo_cnt_q == SIOC_HALF_PERIOD-1);
	assign sioc_hi = (sioc_hi_cnt_q == SIOC_HALF_PERIOD-1);
	
	//ID address handler
	always @(posedge i_clk) begin
		if (i_rst) begin
			id_addr_q <= 8'b0;
			id_addr_bit_q <= 0;
		end else if (sioc_redge && (pstate_q == `ID_ADDRESS) && (id_addr_bit_q < 8)) begin
			id_addr_q <= {id_addr_q[6:0], i_siod_in};
			id_addr_bit_q <= id_addr_bit_q + 1;
		end else if (pstate_q == `IDLE) begin
			id_addr_q <= 8'b0;
			id_addr_bit_q <= 0;
		end
	end
	
	//Sub-address and data handler
	always @(posedge i_clk) begin
		if (i_rst) begin
			bit_cnt_q <= 0;
			byte_cnt_q <= 0;
			wr_data_q <= 8'b0;
		end else if (sioc_redge && (pstate_q == `SUB_ADDRESS_AND_DATA) && (bit_cnt_q < 8)) begin
			bit_cnt_q <= bit_cnt_q + 1;
			if (byte_cnt_q == 2) 
				wr_data_q <= {wr_data_q[6:0], i_siod_in};
		end else if (sioc_redge && (pstate_q == `SUB_ADDRESS_AND_DATA) && (bit_cnt_q == 8)) begin
			bit_cnt_q <= 0;
			byte_cnt_q <= byte_cnt_q + 1;
		end else if (pstate_q == `IDLE) begin
			bit_cnt_q <= 0;
			byte_cnt_q <= 0;
		end
	end
	
	//Read data handler
	always @(posedge i_clk) begin
		if (i_rst) begin
			o_siod_out <= 8'b0;
			wr_data_cnt_q <= 0;
		end else if (pstate_q == `RD_DATA) begin
			if (sioc_lo) begin
				if (wr_data_cnt_q < 8) begin
					o_siod_out <= wr_data_q[7-wr_data_cnt_q];
					wr_data_cnt_q <= wr_data_cnt_q + 1;
				end else 
					wr_data_cnt_q <= 0;
			end	
		end
	end
	
	always @(posedge i_clk) begin
		if (i_rst)
			pstate_q <= `IDLE;
		else
			pstate_q <= nstate;
	end
	
	always @(*) begin
		case (pstate_q)
			`IDLE: begin
				if (sioc_q && siod_fedge)
					nstate = `ID_ADDRESS;
				else
					nstate = pstate_q;
			end
			
			`ID_ADDRESS: begin
				if ((id_addr_bit_q == 8) && (!id_addr_q[0]))
					nstate = `SUB_ADDRESS_AND_DATA;
				else if ((id_addr_bit_q == 8) && id_addr_q[0])
					nstate = `RD_DATA;
				else
					nstate = pstate_q;
			end

			`SUB_ADDRESS_AND_DATA: begin
				if (sioc_q && siod_redge)
					nstate = `IDLE;
				else
					nstate = pstate_q;
			end
			
			`RD_DATA: begin
				if (sioc_lo && (wr_data_cnt_q == 8))
					nstate = `IDLE;
				else
					nstate = pstate_q;
			end
		endcase
	end

	//Output assignments
	assign cs_siod_in_q     = siod_in_q    ;
	assign cs_sioc_q        = sioc_q       ;
	assign cs_sioc_hi_cnt_q = sioc_hi_cnt_q;
	assign cs_sioc_lo_cnt_q = sioc_lo_cnt_q;
	assign cs_id_addr_q     = id_addr_q    ;
	assign cs_id_addr_bit_q = id_addr_bit_q;
	assign cs_bit_cnt_q     = bit_cnt_q    ;
	assign cs_byte_cnt_q    = byte_cnt_q   ;
	assign cs_wr_data_q     = wr_data_q    ;
	assign cs_wr_data_cnt_q = wr_data_cnt_q;
	assign cs_pstate_q      = pstate_q     ;
	assign cs_nstate        = nstate       ;
	assign cs_siod_fedge    = siod_fedge   ;
	assign cs_siod_redge    = siod_redge   ;
	assign cs_sioc_redge    = sioc_redge   ;
	assign cs_sioc_lo       = sioc_lo      ;
	assign cs_sioc_hi       = sioc_hi      ;
	
endmodule
