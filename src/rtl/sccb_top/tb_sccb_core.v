`timescale 1ns / 1ps
module tb_sccb_core ();

  /*TODO:
    - Debug stop logic  
  */

  // System Ports
  reg i_clk, i_rst;
  
  // Top Level Ports
  reg [7:0]  i_tx_data;
  reg        i_tx_start;
  reg        i_tx_stop;
  wire [7:0] o_rx_data;
  wire       o_tx_ready;
  wire       o_rx_ready;
  wire       o_ack;
  wire       o_siod_oe;
  
  // SCCB Ports
  reg  i_siod_in;
  wire o_sioc;
  wire o_siod_out;
  
  // TB/ILA Ports
  wire        cs_sioc_q;
  wire        cs_siod_q;
  wire [8:0]  cs_tx_byte_q;
  wire [7:0]  cs_rx_byte_q;
  wire [3:0]  cs_bit_in_byte_q;
  wire [3:0]  cs_pstate_q;
  wire        cs_update_index;
  wire        cs_update_verify;
  wire        cs_verify_reg_q;
  wire        cs_sioc_lo;
  wire        cs_sioc_hi;
  wire [15:0] cs_clk_cnt_q;
  wire        cs_start_clk_cnt_q;
  
  // TB Signals
  reg [7:0] tx_byte_data [3:0];
  reg [2:0] byte_cnt_q;
  
  //Reset gen
  initial i_rst = 1;
  always #50 i_rst = 0;
  
  //Clock gen
  initial i_clk = 0;
  always #5 i_clk = !i_clk;
  
  initial begin
    tx_byte_data[0] = 8'h78; //cam_address
    tx_byte_data[1] = 8'hbe; //addr msb
    tx_byte_data[2] = 8'hef; //addr lsb
    tx_byte_data[3] = 8'haa; //data
  end
  
  sccb_core #(.SIOC_FREQ(1000000)) DUT (
    .i_clk             (i_clk           ),
    .i_rst             (i_rst           ),
    .i_tx_data         (i_tx_data       ),
    .i_tx_start        (i_tx_start      ),
    .i_tx_stop         (i_tx_stop       ),
    .o_rx_data         (                ),
    .o_tx_ready        (o_tx_ready      ),
    .o_rx_ready        (                ),
    .o_ack             (o_ack           ),
    .o_siod_oe         (o_siod_oe       ),
    .o_sioc            (o_sioc          ),
    .i_siod_in         (1'b0            ),
    .o_siod_out        (o_siod_out      ),
    .cs_sioc_q         (cs_sioc_q       ),
    .cs_siod_q         (cs_siod_q       ),
    .cs_tx_byte_q      (cs_tx_byte_q    ),
    .cs_rx_byte_q      (cs_rx_byte_q    ),
    .cs_bit_in_byte_q  (cs_bit_in_byte_q),
    .cs_pstate_q       (cs_pstate_q     ),
    .cs_update_index   (cs_update_index ),
    .cs_update_verify  (cs_update_verify),
    .cs_verify_reg_q   (cs_verify_reg_q ),
    .cs_sioc_lo        (cs_sioc_lo      ),
    .cs_sioc_hi        (cs_sioc_hi      ),
    .cs_clk_cnt_q      (cs_clk_cnt_q    ),
    .cs_start_clk_cnt_q()
  );
  
  //i_tx_start logic
  always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) 
      i_tx_start <= 1'b0;
    else if ((o_tx_ready) && (byte_cnt_q == 0))
      i_tx_start <= 1'b1;
    else
      i_tx_start <= 1'b0;
  end
  
  //i_tx_data logic
  always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      i_tx_data  <= 8'h00;
      byte_cnt_q <= 0;
    end else if (o_tx_ready && (byte_cnt_q == 0)) begin
      i_tx_data <= tx_byte_data[0];
      byte_cnt_q <= byte_cnt_q + 1;
    end else if (o_ack && (byte_cnt_q <= 3)) begin
      i_tx_data  <= tx_byte_data[byte_cnt_q];
      byte_cnt_q <= byte_cnt_q + 1;
    end
  end
  
  //i_tx_stop logic
  always @(*) begin
    if (i_rst)
      i_tx_stop <= 1'b0;
    else if (o_ack && (byte_cnt_q > 3)) 
      i_tx_stop <= 1'b1;
  end
  
endmodule
  
  
  
  
  
  
  
  
  
  
  
    