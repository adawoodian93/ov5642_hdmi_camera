`timescale 1ns / 1ps

// State definitions
`define IDLE          4'd0
`define START         4'd1
`define TX_DATA       4'd2
`define ACK_SLAVE     4'd3
`define RENEW_TX_DATA 4'd4
`define RX_DATA       4'd5
`define ACK_MASTER    4'd6
`define STOP_1        4'd7
`define STOP_2        4'd8

module sccb_core #(
  parameter SIOC_FREQ = 100000)
(
  // System Ports
  input wire i_clk,
  input wire i_rst,
  
  // sccb_top Interface
  input wire [7:0]  i_tx_data,
  input wire        i_tx_start,
  input wire        i_tx_stop,
  output wire [7:0] o_rx_data,
  output reg        o_tx_ready,
  output reg        o_rx_ready,
  output reg        o_ack,
  output reg        o_siod_oe,
  
  // SCCB Ports
  input wire  i_siod_in,
  output wire o_sioc,
  output wire o_siod_out,
  
  // TB/ILA Ports
  output wire        cs_sioc_q,
  output wire        cs_siod_q,
  output wire [8:0]  cs_tx_byte_q,
  output wire [7:0]  cs_rx_byte_q,
  output wire [3:0]  cs_bit_in_byte_q,
  output wire [3:0]  cs_pstate_q,
  output wire        cs_update_index,
  output wire        cs_update_verify,
  output wire        cs_verify_reg_q,
  output wire        cs_sioc_lo,
  output wire        cs_sioc_hi,
  output wire [15:0] cs_clk_cnt_q,
  output wire        cs_start_clk_cnt_q
);

  //SIOC_PERIOD equals half the number of 100MHz clock cycles in 1 SIOC_FREQ clock cycle
  //before SIOC needs to toggle.
  localparam SIOC_PERIOD = (100_000_000/(SIOC_FREQ*2));
  localparam SIOC_HALF_PERIOD = ((100_000_000/(SIOC_FREQ*2))/2);
  
  reg        sioc_q;
  reg        siod_d;
  reg        siod_q;
  reg [15:0] clk_cnt_q;
  reg [8:0]  tx_byte_d;
  reg [8:0]  tx_byte_q;
  reg [7:0]  rx_byte_d;
  reg [7:0]  rx_byte_q;
  reg [3:0]  bit_in_byte_q;
  reg [3:0]  pstate_q;
  reg [3:0]  nstate;
  reg        update_index;
  reg        update_verify;
  reg        verify_reg_q;
  reg        start_clk_cnt_q;
  
  wire       sioc_lo;
  wire       sioc_hi;
  
  //Free running SIOC clock count logic
  always @(posedge i_clk) begin
    if (i_rst) 
      sioc_q <= 1'b1;
    else if ((pstate_q == `IDLE) || (pstate_q == `START))
      sioc_q <= 1'b1;
    else if (clk_cnt_q == SIOC_PERIOD-1) 
      sioc_q <= !sioc_q;
  end
  
  always @(posedge i_clk) begin
    if (i_rst)
      clk_cnt_q <= 0;
    else if (clk_cnt_q == SIOC_PERIOD-1)
      clk_cnt_q <= 0;
    else 
      clk_cnt_q <= clk_cnt_q + 1;
  end
  
  //-1 because once sioc_lo or sioc_hi is asserted it takes an additional i_clk
  //clock cycles for siod_q to update its value.
  assign sioc_lo = (clk_cnt_q == SIOC_HALF_PERIOD-1) && (sioc_q == 1'b0);
  assign sioc_hi = (clk_cnt_q == SIOC_HALF_PERIOD-1) && (sioc_q == 1'b1);
  
  //Register SIOD to retain value transitioning state to state
  always @(posedge i_clk) begin
    if (i_rst) 
      siod_q <= 1'b1;
    else
      siod_q <= siod_d;
  end
  
  //Register tx_byte_q and rx_byte_q
  always @(posedge i_clk) begin
    if (i_rst) begin
      tx_byte_q <= 9'h000;
      rx_byte_q <= 8'h00;
    end else begin
      tx_byte_q <= tx_byte_d;
      rx_byte_q <= rx_byte_d;
    end
  end
 
  //Update values
  always @(posedge i_clk) begin
    if (i_rst) begin
      verify_reg_q  <= 1'b0;
      bit_in_byte_q <= 8;
    end else begin
      if (update_index) begin
        if (((!verify_reg_q) && (pstate_q == `ACK_SLAVE)) || (pstate_q == `STOP_2))
          bit_in_byte_q <= 8;
        else if (verify_reg_q && (pstate_q == `ACK_SLAVE))
          bit_in_byte_q <= 7;
        else
          bit_in_byte_q <= bit_in_byte_q - 1;
      end
      
      if (update_verify && (pstate_q == `START))
        verify_reg_q <= i_tx_data[0];
      else if (update_verify && (pstate_q == `ACK_SLAVE))
        verify_reg_q <= 1'b0;
    end
  end
  
  //State machine
  always @(posedge i_clk) begin
    if (i_rst)
      pstate_q <= `IDLE;
    else
      pstate_q <= nstate;
  end
  
  always @(*) begin
    nstate        <= `IDLE;
    siod_d        <= siod_q;
    tx_byte_d     <= tx_byte_q;
    rx_byte_d     <= rx_byte_q;
    o_tx_ready    <= 1'b0;
    o_rx_ready    <= 1'b0;
    o_siod_oe     <= 1'b0;
    o_ack         <= 1'b0;
    update_index  <= 1'b0;
    update_verify <= 1'b0;
    case (pstate_q)
      //siod = z
      `IDLE: begin
        o_siod_oe  <= 1'b1;
        o_tx_ready <= 1'b1;
        if (i_tx_start) 
          nstate <= `START;
        else
          nstate <= `IDLE;
      end
      
      //Transition from IDLE to START i_tx_data is valid 
      //siod = 1 -> siod = 0
      `START: begin
        siod_d        <= 1'b1;
        tx_byte_d     <= {i_tx_data, 1'b1}; //i_tx_data[0] = R/W bit; Append ACK bit to i_tx_data
        update_verify <= i_tx_data[0] ? 1'b1 : 1'b0; //Check R/W bit
        if (sioc_hi) begin
          siod_d   <= 1'b0;
          nstate <= `TX_DATA;
        end else
          nstate <= `START;
      end
      
      //Transmit tx_byte_q serially MSB first
      //siod = tx_byte_q[8]
      `TX_DATA: begin
        if (sioc_lo) begin
          siod_d <= tx_byte_q[bit_in_byte_q];
          update_index <= (bit_in_byte_q == 0) ? 1'b0 : 1'b1;
          if (bit_in_byte_q == 0) begin
            nstate <= `ACK_SLAVE;
          end else 
            nstate <= `TX_DATA;
        end else
          nstate <= `TX_DATA;
      end
      
      //Wait for response from slave upon transmission of ACK bit (9th bit).
      //Assert o_ack which will prompt sccb_top to assert i_tx_stop if all bytes of current 
      //transaction have been transmitted to slave causing the state machine to enter into  
      //IDLE state to make ready for read transaction, RX_DATA when within a read transaction,
      //or RENEW_TX_DATA state to transmit the next byte.
      `ACK_SLAVE: begin
        o_siod_oe <= 1'b1;
        if (sioc_hi) begin
          o_ack <= 1'b1;
          if (i_tx_stop)
            nstate <= `STOP_1;
          else if (verify_reg_q) begin
            update_verify <= 1'b1; //Clear verify_reg_q
            update_index  <= 1'b1; //Reset bit_in_byte_q to 7
            nstate        <= `RX_DATA;
          end else begin
            update_index <= 1'b1; //Reset bit_in_byte_q to 8
            nstate <= `RENEW_TX_DATA;
          end
        end else
          nstate <= `ACK_SLAVE;
      end
      
      //bit_in_byte_q will be 8 transitioning into this state.
      `RENEW_TX_DATA: begin
        o_siod_oe    <= 1'b1;
        tx_byte_d    <= {i_tx_data, 1'b1};
        if (sioc_lo) begin
          update_index <= 1'b1;
          siod_d <= tx_byte_q[bit_in_byte_q]; //This line ensures that MSB of next byte is ready to transmit
          nstate <= `TX_DATA;
        end else
          nstate <= `RENEW_TX_DATA;
      end
        
      //bit_in_byte_q will be 7 transitioning into this state.
	  `RX_DATA: begin
        o_siod_oe <= 1'b1;
        if (sioc_hi) begin
          rx_byte_d[bit_in_byte_q] <= i_siod_in;
          update_index <= 1'b1;
          nstate <= `RX_DATA;
          if (bit_in_byte_q == 0) begin //Checks to see if last bit has been received from slave during sioc_hi before updating index
            update_index <= 1'b0;
            nstate <= `ACK_MASTER;
          end
        end else
          nstate <= `RX_DATA;
      end
      
      `ACK_MASTER: begin
        if (sioc_hi) begin
          o_rx_ready <= 1'b1;
          siod_d     <= 1'b1;
          nstate     <= `STOP_1;
        end else
          nstate <= `ACK_MASTER;
      end
      
      `STOP_1: begin
        if (sioc_lo) begin
          siod_d <= 1'b0;
          nstate <= `STOP_2;
        end else
          nstate <= `STOP_1;
      end
      
      `STOP_2: begin
        update_index <= 1'b1;
        if (sioc_hi) begin
          siod_d <= 1'b1;
		 nstate <= `STOP_2;
        end else if (siod_q)
          nstate <= `IDLE;
        else
          nstate <= `STOP_2;
      end
      
      default: begin
        nstate <= `IDLE;
      end
    endcase
  end
        
  //Output Assignments
  assign o_rx_data          = rx_byte_q;
  assign o_sioc             = sioc_q;
  assign o_siod_out         = siod_q;
  assign cs_sioc_q          = sioc_q;       
  assign cs_siod_q          = siod_q;       
  assign cs_tx_byte_q       = tx_byte_q;    
  assign cs_rx_byte_q       = rx_byte_q;    
  assign cs_bit_in_byte_q   = bit_in_byte_q;
  assign cs_pstate_q        = pstate_q;     
  assign cs_update_index    = update_index; 
  assign cs_update_verify   = update_verify;
  assign cs_verify_reg_q    = verify_reg_q; 
  assign cs_sioc_lo         = sioc_lo;      
  assign cs_sioc_hi         = sioc_hi;     
  assign cs_clk_cnt_q       = clk_cnt_q;
  assign cs_start_clk_cnt_q = start_clk_cnt_q;
  
endmodule
        
        
        
        
        
        
        
        
        
      
      
      
      
      
      
      
        