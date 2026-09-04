/*
 * Copyright (c) 2024 Parvathy Nair Karippanal
 * SPDX-License-Identifier: Apache-2.0
 * 
 * Title: Configurable SPI Master Controller (Backend OpenLane ASIC Project)
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (1 = output, 0 = input)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Pin Assignments:
    // ui_in[7:0] -> TX Data Byte to transmit
    // uio_in[0]  -> MISO (Master In Slave Out)
    // uo_out[0]  -> SCLK (Serial Clock)
    // uo_out[1]  -> MOSI (Master Out Slave In)
    // uo_out[2]  -> CS_N (Chip Select Active Low)
    // uo_out[3]  -> Busy Flag
    // uo_out[7:4]-> Received RX Data (lower 4 bits)

    wire [7:0] tx_data = ui_in;
    wire       miso    = uio_in[0];

    reg        sclk_reg;
    reg        mosi_reg;
    reg        cs_n_reg;
    reg        busy_reg;
    reg [7:0]  shift_reg;
    reg [7:0]  rx_reg;
    reg [2:0]  bit_cnt;
    reg [3:0]  clk_divider;

    // Fixed IO direction: All uo_out active, uio pins set cleanly
    assign uio_oe  = 8'b00000000;
    assign uio_out = 8'b00000000;
    assign uo_out  = {rx_reg[3:0], busy_reg, cs_n_reg, mosi_reg, sclk_reg};

    localtype_state;
    reg [1:0] state;
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam SHIFT = 2'b10;
    localparam STOP  = 2'b11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            sclk_reg    <= 1'b0;
            mosi_reg    <= 1'b0;
            cs_n_reg    <= 1'b1;
            busy_reg    <= 1'b0;
            bit_cnt     <= 3'b0;
            clk_divider <= 4'b0;
            shift_reg   <= 8'b0;
            rx_reg      <= 8'b0;
        end else if (ena) begin
            case (state)
                IDLE: begin
                    sclk_reg <= 1'b0;
                    cs_n_reg <= 1'b1;
                    busy_reg <= 1'b0;
                    if (ui_in != 8'h00) begin
                        shift_reg <= tx_data;
                        busy_reg  <= 1'b1;
                        state     <= START;
                    end
                end

                START: begin
                    cs_n_reg <= 1'b0;
                    bit_cnt  <= 3'd7;
                    state    <= SHIFT;
                end

                SHIFT: begin
                    clk_divider <= clk_divider + 1'b1;
                    if (clk_divider == 4'h7) begin
                        sclk_reg <= ~sclk_reg;
                        if (sclk_reg == 1'b0) begin
                            mosi_reg  <= shift_reg[7];
                        end else begin
                            shift_reg <= {shift_reg[6:0], miso};
                            if (bit_cnt == 0) begin
                                state <= STOP;
                            end else begin
                                bit_cnt <= bit_cnt - 1'b1;
                            end
                        end
                    end
                end

                STOP: begin
                    cs_n_reg <= 1'b1;
                    busy_reg <= 1'b0;
                    rx_reg   <= shift_reg;
                    state    <= IDLE;
                end
            endcase
        end
    end

endmodule
