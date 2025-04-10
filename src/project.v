/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_hrv (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
module tt_um_rmssd (
    input  wire [7:0] ui_in,   // [0]: clk, [1]: rst_n, [2]: bit_in, [3]: bit_valid, [4]: rr_valid
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);

    // Assign unused IOs to 0
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire clk        = ui_in[0];
    wire rst_n      = ui_in[1];
    wire bit_in     = ui_in[2];
    wire bit_valid  = ui_in[3];
    wire rr_valid   = ui_in[4];

    wire [7:0] rmssd_out;
    wire done;

    rmssd_serial #(
        .RR_COUNT(8)
    ) core (
        .clk(clk),
        .rst_n(rst_n),
        .bit_in(bit_in),
        .bit_valid(bit_valid),
        .rr_valid(rr_valid),
        .rmssd_out(rmssd_out),
        .done(done)
    );

    assign uo_out = {done, rmssd_out[6:0]}; // 7 bits of result + done

endmodule
  // All output pins must be assigned. If not used, assign to 0.
 // assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{clk,1'b0};

endmodule
module rmssd_serial #(
    parameter RR_COUNT = 8
)(
    input wire clk,
    input wire rst_n,
    input wire bit_in,
    input wire bit_valid,
    input wire rr_valid,
    output reg [7:0] rmssd_out,
    output reg done
);

    reg [7:0] rr_buffer [0:RR_COUNT-1];
    reg [7:0] rr_shift_reg;
    reg [3:0] bit_counter;
    reg [3:0] rr_counter;
    reg [15:0] sum_sq_diff;
    reg [7:0] rr_prev;
    reg calc_done;

    // State Machine
    typedef enum logic [1:0] {
        IDLE, COLLECT, CALC, DONE
    } state_t;

    state_t state;

    // Square root approximation function
    function [7:0] sqrt_approx(input [15:0] x);
        integer i;
        reg [7:0] result;
        begin
            result = 0;
            for (i = 15; i >= 0; i = i - 2) begin
                result = result << 1;
                if ((result + 1)*(result + 1) <= (x >> i))
                    result = result + 1;
            end
            sqrt_approx = result;
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            rr_counter <= 0;
            rr_shift_reg <= 0;
            sum_sq_diff <= 0;
            rr_prev <= 0;
            rmssd_out <= 0;
            done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (bit_valid) begin
                        rr_shift_reg <= {rr_shift_reg[6:0], bit_in};
                        bit_counter <= bit_counter + 1;
                    end
                    if (bit_counter == 7 && rr_valid) begin
                        rr_buffer[rr_counter] <= {rr_shift_reg[6:0], bit_in};
                        rr_counter <= rr_counter + 1;
                        bit_counter <= 0;
                        if (rr_counter == RR_COUNT - 1)
                            state <= CALC;
                    end
                end

                CALC: begin
                    sum_sq_diff <= 0;
                    for (int i = 1; i < RR_COUNT; i = i + 1) begin
                        sum_sq_diff <= sum_sq_diff + (rr_buffer[i] - rr_buffer[i-1])**2;
                    end
                    rmssd_out <= sqrt_approx(sum_sq_diff >> 3);
                    done <= 1;
                    state <= DONE;
                end

                DONE: begin
                    // Hold the result
                end
            endcase
        end
    end

endmodule

