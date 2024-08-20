`timescale 1ns / 1ps
module output_serdes (
    input wire       i_pdata_clk,
    input wire       i_sdata_clk,
    input wire       i_rst, //Synchronous to i_pdata_clk
    input wire [9:0] i_pdata,
    
    output wire      o_sdata_p,
    output wire      o_sdata_n
);

    wire sdata_oq;
    wire slv_shiftout2;
    wire slv_shiftout1;
    
    OBUFDS #(
        .IOSTANDARD("TMDS_33"), // Specify the output I/O standard
        .SLEW("SLOW")           // Specify the output slew rate
    ) OBUFDS_inst (
        .O (o_sdata_p),     // Diff_p output (connect directly to top-level port)
        .OB(o_sdata_n),   // Diff_n output (connect directly to top-level port)
        .I (sdata_oq)      // Buffer input
    );
    
    OSERDESE2 #(
        .DATA_RATE_OQ  ("DDR"),   // DDR, SDR
        .DATA_RATE_TQ  ("SDR"),   // DDR, BUF, SDR
        .DATA_WIDTH    (10),        // Parallel data width (2-8,10,14)
        .SERDES_MODE   ("MASTER"), // MASTER, SLAVE
        .TBYTE_CTL     ("FALSE"),    // Enable tristate byte operation (FALSE, TRUE)
        .TBYTE_SRC     ("FALSE"),    // Tristate byte source (FALSE, TRUE)
        .TRISTATE_WIDTH(1)      // 3-state converter width (1,4)
    )
    OSERDESE2_mst (
        .OFB      (),   // 1-bit output: Feedback path for data
        .OQ       (sdata_oq), // 1-bit output: Data path output
        // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .TBYTEOUT (),            // 1-bit output: Byte group tristate
        .TFB      (),            // 1-bit output: 3-state control
        .TQ       (),            // 1-bit output: 3-state control
        .CLK      (i_sdata_clk), // 1-bit input: High speed clock
        .CLKDIV   (i_pdata_clk), // 1-bit input: Divided clock
        // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
        .D1       (i_pdata[0]),
        .D2       (i_pdata[1]),
        .D3       (i_pdata[2]),
        .D4       (i_pdata[3]),
        .D5       (i_pdata[4]),
        .D6       (i_pdata[5]),
        .D7       (i_pdata[6]),
        .D8       (i_pdata[7]),
        .OCE      (1'b1),       // 1-bit input: Output data clock enable
        .RST      (i_rst),      // 1-bit input: Reset
        // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
        .SHIFTIN1 (slv_shiftout1),
        .SHIFTIN2 (slv_shiftout2),
        // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
        .T1       (1'b0),
        .T2       (1'b0),
        .T3       (1'b0),
        .T4       (1'b0),
        .TBYTEIN  (1'b0),      // 1-bit input: Byte group tristate
        .TCE      (1'b0)       // 1-bit input: 3-state clock enable
    );
    
    OSERDESE2 #(
        .DATA_RATE_OQ  ("DDR"),   // DDR, SDR
        .DATA_RATE_TQ  ("SDR"),   // DDR, BUF, SDR
        .DATA_WIDTH    (10),         // Parallel data width (2-8,10,14)
        .SERDES_MODE   ("SLAVE"), // MASTER, SLAVE
        .TBYTE_CTL     ("FALSE"),    // Enable tristate byte operation (FALSE, TRUE)
        .TBYTE_SRC     ("FALSE"),    // Tristate byte source (FALSE, TRUE)
        .TRISTATE_WIDTH(1)      // 3-state converter width (1,4)
    )
    OSERDESE2_slv (
        .OFB      (),             // 1-bit output: Feedback path for data
        .OQ       (),               // 1-bit output: Data path output
        // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
        .SHIFTOUT1(slv_shiftout1),
        .SHIFTOUT2(slv_shiftout2),
        .TBYTEOUT (),   // 1-bit output: Byte group tristate
        .TFB      (),             // 1-bit output: 3-state control
        .TQ       (),               // 1-bit output: 3-state control
        .CLK      (i_sdata_clk),             // 1-bit input: High speed clock
        .CLKDIV   (i_pdata_clk),       // 1-bit input: Divided clock
        // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
        .D1       (),
        .D2       (),
        .D3       (i_pdata[8]),
        .D4       (i_pdata[9]),
        .D5       (),
        .D6       (),
        .D7       (),
        .D8       (),
        .OCE      (1'b1),             // 1-bit input: Output data clock enable
        .RST      (i_rst),             // 1-bit input: Reset
        // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0),
        // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
        .T1     (1'b0),
        .T2     (1'b0),
        .T3     (1'b0),
        .T4     (1'b0),
        .TBYTEIN(1'b0),     // 1-bit input: Byte group tristate
        .TCE    ()              // 1-bit input: 3-state clock enable
    );
    
endmodule