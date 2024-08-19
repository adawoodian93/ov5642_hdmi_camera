`timescale 1ns / 1ps

// State definitions
`define IDLE     4'd0
`define INIT_REG 4'd1
`define VERIFY   4'd2
`define DONE     4'd3
`define ERROR    4'd4

module sccb_top (
  // System Ports
  input wire         i_clk,
  input wire         i_rst,
  input wire         i_start_init,
  
  // SCCB Ports
  output wire        o_sioc,
  input wire         i_siod_in,
  output wire        o_siod_out,
  output wire        o_siod_oe,
  
  // Status LEDs
  output reg         o_done_led,
  output reg         o_err_led,
  
  // TB/ILA Ports
  //sccb_top
  output wire [7:0]  cs_tx_data_q,
  output wire        cs_start,
  output wire        cs_stop,
  output wire [9:0]  cs_reg_idx_q,
  output wire [2:0]  cs_byte_cnt_q,
  output wire [1:0]  cs_err_cnt_q,
  output wire        cs_update_tx_byte,
  output wire        cs_update_rx_byte,
  output wire        cs_init_done,
  output wire        cs_inc_addr,
  output wire [2:0]  cs_pstate_q_top,
  output wire [7:0]  cs_rx_data,
  output wire        cs_tx_ready,
  output wire        cs_rx_ready,
  output wire [15:0] cs_reg_addr,
  output wire [7:0]  cs_reg_data,
  output wire        cs_verify_reg,
  output wire        cs_ack,
  
  //sccb_core
  output wire        cs_sioc_q,
  output wire        cs_siod_q,
  output wire [8:0]  cs_tx_byte_q,
  output wire [7:0]  cs_rx_byte_q,
  output wire [3:0]  cs_bit_in_byte_q,
  output wire [3:0]  cs_pstate_q_core,
  output wire        cs_update_index,
  output wire        cs_update_verify,
  output wire        cs_verify_reg_q,
  output wire        cs_sioc_lo,
  output wire        cs_sioc_hi,
  output wire [15:0] cs_clk_cnt_q,
  output wire        cs_start_clk_cnt_q
);

  localparam CAM_ADDRESS = 8'h78;
  
  reg [7:0]   tx_data_q;
  reg         start;
  reg         stop;
  reg [9:0]   reg_idx_q;
  reg [2:0]   byte_cnt_q;
  reg [1:0]   err_cnt_q;  
  reg         update_tx_byte, update_rx_byte, update_err_cnt;
  reg         inc_addr;
  reg [2:0]   nstate, pstate_q;
  reg         start_init_q;
  
  wire [7:0]  rx_data;
  wire        tx_ready;
  wire        rx_ready;
  wire [15:0] reg_addr;
  wire [7:0]  reg_data;
  wire        verify_reg;
  wire        ack;
  wire        init_done;
  
  sccb_core #(.SIOC_FREQ(1000000)) u_sccb (
    .i_clk             (i_clk           ),
    .i_rst             (i_rst           ),
    .i_tx_data         (tx_data_q       ),
    .i_tx_start        (start           ),
    .i_tx_stop         (stop            ),
    .o_rx_data         (rx_data         ),
    .o_tx_ready        (tx_ready        ),
    .o_rx_ready        (rx_ready        ),
    .o_ack             (ack             ),
    .o_siod_oe         (o_siod_oe       ),
    .o_sioc            (o_sioc          ),
    .i_siod_in         (i_siod_in       ),
    .o_siod_out        (o_siod_out      ),
    .cs_sioc_q         (cs_sioc_q       ),
    .cs_siod_q         (cs_siod_q       ),
    .cs_tx_byte_q      (cs_tx_byte_q    ),
    .cs_rx_byte_q      (cs_rx_byte_q    ),
    .cs_bit_in_byte_q  (cs_bit_in_byte_q),
    .cs_pstate_q       (cs_pstate_q_core),
    .cs_update_index   (cs_update_index ),
    .cs_update_verify  (cs_update_verify),
    .cs_verify_reg_q   (cs_verify_reg_q ),
    .cs_sioc_lo        (cs_sioc_lo      ),
    .cs_sioc_hi        (cs_sioc_hi      ),
    .cs_clk_cnt_q      (cs_clk_cnt_q    ),
    .cs_start_clk_cnt_q(                )
  );
  
  ov5642_init_regs u_init_regs (
    .i_addr  (reg_idx_q           ),
    .o_data  ({reg_addr, reg_data}),
    .o_verify(verify_reg          )
  );	
  
  assign init_done = ({reg_addr, reg_data} == 24'hffff_ff) ? 1'b1: 1'b0;
  
  //Update values
  always @(posedge i_clk) begin
    if (i_rst) begin
      tx_data_q  <= CAM_ADDRESS;
      byte_cnt_q <= 0;
      err_cnt_q  <= 0;
    end else if (update_tx_byte) begin
      case (byte_cnt_q)
        0: begin
          tx_data_q  <= CAM_ADDRESS;
          byte_cnt_q <= byte_cnt_q + 1;
        end
        
        1: begin
          tx_data_q  <= reg_addr[15:8];
          byte_cnt_q <= byte_cnt_q + 1;
        end
        
        2: begin
          tx_data_q  <= reg_addr[7:0];
          byte_cnt_q <= byte_cnt_q + 1;
        end
        
        3: begin
          tx_data_q  <= reg_data;
          byte_cnt_q <= 0;
        end
        
        default: begin
          byte_cnt_q <= 0;
        end
      endcase
    end else if (update_rx_byte) //Data to be sent for read transcation
      tx_data_q <= CAM_ADDRESS + 1;
    else if (update_err_cnt) begin
      if (rx_data != reg_data)
        err_cnt_q <= err_cnt_q + 1;
      else
        err_cnt_q <= 0;
    end
  end

  always @(posedge i_clk) begin
    if (i_rst)
	  reg_idx_q <= 10'h000;
	else if (inc_addr)
	  reg_idx_q <= reg_idx_q + 1;
  end
  
  always @(posedge i_clk) begin
	if (i_rst)
	  start_init_q <= 1'b0;
	else if (i_start_init)
	  start_init_q <= 1'b1;
	else if (o_done_led || o_err_led)
	  start_init_q <= 1'b0;
  end
  
  always @(posedge i_clk) begin
    if (i_rst)
      pstate_q <= `IDLE;
    else
      pstate_q <= nstate;
  end
  
  //State Machine
  always @(*) begin
    nstate         <= `IDLE;
    start          <= 1'b0;
    stop           <= 1'b0;
    inc_addr       <= 1'b0;
    o_done_led     <= 1'b0;
    o_err_led      <= 1'b0;
    update_rx_byte <= 1'b0;
    update_tx_byte <= 1'b0;
    update_err_cnt <= 1'b0;
    case (pstate_q)
      //Check for done condition was also added to IDLE state because in VERIFY state
      //the register address incrementing (inc_addr) and state transition to IDLE takes
      //one clock cycle. Therefore, the register address and the data to be written will
      //update when transitioning back to IDLE from VERIFY state.
      `IDLE: begin
        if (tx_ready && start_init_q) begin
          if (init_done)
            nstate <= `DONE;
          else begin 
            start          <= 1'b1;
            update_tx_byte <= 1'b1;
            nstate         <= `INIT_REG;
          end
        end else
          nstate <= `IDLE;
      end

      //tx_ready will remain low in this state until
      //current config value has been transmitted. Only
      //when a register that needs verification will
      //transistion the FSM into the VERIFY state.
      //byte_cnt_q will be 0 transitioning 
      //to VERIFY state.
      //Increment register module's address on final 'ack'
      //of current register address/data pair as opposed to
      //receipt of tx_ready from sccb_core. This will avoid
      //timing issues with the final address/data pair so that
      //init_done is asserted before sccb_core enters its IDLE
      //state so that we do not start another transmission
      //unnecessarily.
	  //Increment address on second sub-address byte in write transmission
	  //so that when updating TX byte on write data byte of current write transmission
	  //the ID address of the next write transmission is ready to be transmitted.
	  //Address is not incremented when register verification is required so that 
	  //data read from slave can be properly compared with the data that was transmitted
	  //during the write transmission.
      `INIT_REG: begin
        if (tx_ready && verify_reg) begin
          start          <= 1'b1;
          update_rx_byte <= 1'b1;
          nstate         <= `VERIFY;
        end else if (tx_ready && !verify_reg && !init_done) begin
          start    <= 1'b1;
          nstate   <= `INIT_REG;
        end else if (ack) begin   
          update_tx_byte <= (verify_reg && (byte_cnt_q == 0)) ? 1'b0 : 1'b1;
          nstate         <= `INIT_REG;
          if (byte_cnt_q == 0) begin
            stop <= 1'b1;
          end else if ((byte_cnt_q == 3) && (!verify_reg))
            inc_addr <= 1'b1;
        end else if (tx_ready && init_done)
          nstate <= `DONE;
        else
          nstate <= `INIT_REG;
      end

      //rx_ready indicates that data has been read from slave's register and is ready. Only increment 
      //register address if received data matches data transmitted in TX transaction.
      `VERIFY: begin
        if (rx_ready) begin 
          update_err_cnt <= 1'b1;
          if (err_cnt_q == 3) 
            nstate <= `ERROR;
          else begin
            nstate <= `IDLE;
            inc_addr <= (rx_data == reg_data) ? 1'b1 : 1'b0; //Increment config register only if TX data matches RX data
          end
        end else
          nstate <= `VERIFY;
      end

      `DONE: begin
        o_done_led <= 1'b1; //Depends if active high or low needed
        nstate <= `DONE;
      end

      `ERROR: begin
        o_err_led  <= 1'b1; //Depends if active high or low needed
        nstate <= `ERROR;
      end
	  
      default: begin
        nstate <= `IDLE;
      end
    endcase
  end
  
  //Output Assignment
  assign cs_tx_data_q      = tx_data_q;
  assign cs_start          = start;
  assign cs_stop           = stop;
  assign cs_reg_idx_q      = reg_idx_q;
  assign cs_byte_cnt_q     = byte_cnt_q;
  assign cs_err_cnt_q      = err_cnt_q;
  assign cs_update_tx_byte = update_tx_byte;
  assign cs_update_rx_byte = update_rx_byte;
  assign cs_init_done      = init_done;
  assign cs_inc_addr       = inc_addr;
  assign cs_pstate_q_top   = pstate_q;
  assign cs_rx_data        = rx_data;
  assign cs_tx_ready       = tx_ready;
  assign cs_rx_ready       = rx_ready;
  assign cs_reg_addr       = reg_addr;
  assign cs_reg_data       = reg_data;
  assign cs_verify_reg     = verify_reg;
  assign cs_ack            = ack;
  
endmodule
		
		
		
		
		
		
		
	  
	  