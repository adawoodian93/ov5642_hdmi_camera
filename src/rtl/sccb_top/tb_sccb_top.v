`timescale 1ns / 1ps
module tb_sccb_top ();

  // System Ports
  reg i_clk, i_rst, i_start_init;
  
  // SCCB Ports
  wire i_siod_in;
  wire o_sioc;
  wire o_siod_out;
  wire o_siod_oe;
  wire o_done_led;
  wire o_err_led;
  
  // TB/ILA Ports
  //sccb_top
  wire [7:0]  cs_tx_data_q;
  wire        cs_start;
  wire        cs_stop;
  wire [9:0]  cs_reg_idx_q;
  wire [2:0]  cs_byte_cnt_q_mst;
  wire [1:0]  cs_err_cnt_q;
  wire        cs_update_tx_byte;
  wire        cs_update_rx_byte;
  wire        cs_init_done;
  wire        cs_inc_addr;
  wire [2:0]  cs_pstate_q_top;
  wire [7:0]  cs_rx_data;
  wire        cs_tx_ready;
  wire        cs_rx_ready;
  wire [15:0] cs_reg_addr;
  wire [7:0]  cs_reg_data;
  wire        cs_verify_reg;
  wire        cs_ack;
  
  //sccb_core
  wire        cs_sioc_q_mst;
  wire        cs_siod_q;
  wire [8:0]  cs_tx_byte_q;
  wire [7:0]  cs_rx_byte_q;
  wire [3:0]  cs_bit_in_byte_q;
  wire [3:0]  cs_pstate_q_core;
  wire        cs_update_index;
  wire        cs_update_verify;
  wire        cs_verify_reg_q;
  wire        cs_sioc_lo_mst;
  wire        cs_sioc_hi_mst;
  wire [15:0] cs_clk_cnt_q;
  wire        cs_start_clk_cnt_q;
  
  //sccb_slave
  wire       cs_siod_in_q;
  wire       cs_sioc_q_slv;
  wire [3:0] cs_sioc_hi_cnt_q;
  wire [3:0] cs_sioc_lo_cnt_q;
  wire [7:0] cs_id_addr_q;
  wire [3:0] cs_id_addr_bit_q;
  wire [3:0] cs_bit_cnt_q;
  wire [1:0] cs_byte_cnt_q_slv;
  wire [7:0] cs_wr_data_q;
  wire [3:0] cs_wr_data_cnt_q;
  wire [2:0] cs_pstate_q;
  wire [2:0] cs_nstate;
  wire       cs_siod_fedge;
  wire       cs_siod_redge;
  wire       cs_sioc_redge;
  wire       cs_sioc_lo_slv;
  wire       cs_sioc_hi_slv;
  
  //Reset gen
  initial i_rst = 1;
  always #55 i_rst = 0;
  
  //Clock gen
  initial i_clk = 0;
  always #5 i_clk = !i_clk;
  
  sccb_top DUT_sccb_top (
    .i_clk             (i_clk            ),
    .i_rst             (i_rst            ),
    .i_start_init      (i_start_init     ),
    .o_sioc            (o_sioc           ),
    .i_siod_in         (i_siod_in        ),
    .o_siod_out        (o_siod_out       ),
    .o_siod_oe         (o_siod_oe        ),
    .o_done_led        (o_done_led       ),
    .o_err_led         (o_err_led        ),
    .cs_tx_data_q      (cs_tx_data_q     ),
    .cs_start          (cs_start         ),
    .cs_stop           (cs_stop          ),
    .cs_reg_idx_q      (cs_reg_idx_q     ),
    .cs_byte_cnt_q     (cs_byte_cnt_q_mst),
    .cs_err_cnt_q      (cs_err_cnt_q     ),
    .cs_update_tx_byte (cs_update_tx_byte),
    .cs_update_rx_byte (cs_update_rx_byte),
    .cs_init_done      (cs_init_done     ),
    .cs_inc_addr       (cs_inc_addr      ),
    .cs_pstate_q_top   (cs_pstate_q_top  ),
    .cs_rx_data        (cs_rx_data       ),
    .cs_tx_ready       (cs_tx_ready      ),
    .cs_rx_ready       (cs_rx_ready      ),
    .cs_reg_addr       (cs_reg_addr      ),
    .cs_reg_data       (cs_reg_data      ),
    .cs_verify_reg     (cs_verify_reg    ),
    .cs_ack            (cs_ack           ),
    .cs_sioc_q         (cs_sioc_q_mst    ),
    .cs_siod_q         (cs_siod_q        ),
    .cs_tx_byte_q      (cs_tx_byte_q     ),
    .cs_rx_byte_q      (cs_rx_byte_q     ),
    .cs_bit_in_byte_q  (cs_bit_in_byte_q ),
    .cs_pstate_q_core  (cs_pstate_q_core ),
    .cs_update_index   (cs_update_index  ),
    .cs_update_verify  (cs_update_verify ),
    .cs_verify_reg_q   (cs_verify_reg_q  ),
    .cs_sioc_lo        (cs_sioc_lo_mst   ),
    .cs_sioc_hi        (cs_sioc_hi_mst   ),
    .cs_clk_cnt_q      (cs_clk_cnt_q     ),
    .cs_start_clk_cnt_q(                 )
  );
  
  sccb_slave #(.SIOC_FREQ(1000000)) DUT_sccb_slave (
    .i_clk           (i_clk            ),
    .i_rst           (i_rst            ),
    .i_sioc          (o_sioc           ),
    .i_siod_in       (o_siod_out       ),
    .o_siod_out      (i_siod_in        ),
    .cs_siod_in_q    (cs_siod_in_q     ),
    .cs_sioc_q       (cs_sioc_q_slv    ),
    .cs_sioc_hi_cnt_q(cs_sioc_hi_cnt_q ),
    .cs_sioc_lo_cnt_q(cs_sioc_lo_cnt_q ),
    .cs_id_addr_q    (cs_id_addr_q     ),
    .cs_id_addr_bit_q(cs_id_addr_bit_q ),
    .cs_bit_cnt_q    (cs_bit_cnt_q     ),
    .cs_byte_cnt_q   (cs_byte_cnt_q_slv),
    .cs_wr_data_q    (cs_wr_data_q     ),
    .cs_wr_data_cnt_q(cs_wr_data_cnt_q ),
    .cs_pstate_q     (cs_pstate_q      ),
    .cs_nstate       (cs_nstate        ),
    .cs_siod_fedge   (cs_siod_fedge    ),
    .cs_siod_redge   (cs_siod_redge    ),
    .cs_sioc_redge   (cs_sioc_redge    ),
    .cs_sioc_lo      (cs_sioc_lo_slv   ),
    .cs_sioc_hi      (cs_sioc_hi_slv   )
  );

  //Stimuli generation
  initial begin
    i_start_init = 1'b0;
    #65 i_start_init = 1'b1;
    #10 i_start_init = 1'b0;
  end
  
endmodule
  
  
  
  
  
  
  
  
  
  
  
    