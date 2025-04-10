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

  // All output pins must be assigned. If not used, assign to 0.
 // assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
     module tt_um_rmssd (
    input wire clk, // Clock input
    input wire rst_n, // Active-low reset
    input wire [7:0] rr_in, // RR interval input (8-bit)
    input wire valid, // Input valid signal
    output reg [7:0] rmssd_out, // RMSSD output (8-bit)
    output reg done // Computation done signal
);

    // Registers for storing previous RR interval and squared differences
    reg [7:0] rr_prev;
    reg [15:0] sum_sq_diff;
    reg [3:0] count;

    // State machine
    reg [1:0] state;
    localparam IDLE = 2'b00, READ = 2'b01, CALC = 2'b10, DONE = 2'b11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_prev <= 0;
            sum_sq_diff <= 0;
            count <= 0;
            state <= IDLE;
            rmssd_out <= 0;
            done <= 0;
        end 
        else begin
            case (state)
                IDLE: begin
                    if (valid) begin
                        state <= READ;
                    end
                end

                READ: begin
                    if (count == 0) begin
                        rr_prev <= rr_in;
                        count <= count + 1;
                    end else begin
                        // Compute difference squared
                        sum_sq_diff <= sum_sq_diff + ((rr_in - rr_prev) * (rr_in - rr_prev));
                        rr_prev <= rr_in;
                        count <= count + 1;
                        if (count == 7) state <= CALC;
                    end
                end

                CALC: begin
                    // Compute square root using shift-based approximation
                    rmssd_out <= sqrt_approx(sum_sq_diff >> 3); // Divide by N=8
                    state <= DONE;
                end

                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

    // Shift-based Square Root Approximation
    function [7:0] sqrt_approx(input [15:0] x);
        integer i;
        reg [7:0] result;
        begin
            result = 0;
            for (i = 15; i >= 0; i = i - 2) begin
                result = result << 1;
                if ((result + 1) * (result + 1) <= (x >> i))
                    result = result + 1;
            end
            sqrt_approx = result;
        end
    endfunction

endmodule


  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
