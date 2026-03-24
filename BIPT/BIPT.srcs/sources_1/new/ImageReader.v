`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.03.2026
// Design Name: 
// Module Name: ImageReader
// Project Name: BIPT - FPGA Image Processing
// Target Devices: Nexys4 DDR (xc7a100tcsg324-1)
// Description: Reads image metadata (WIDTH, HEIGHT) and pixel data from Block RAM
//              Supports variable resolution (up to 640x480)
//
//////////////////////////////////////////////////////////////////////////////////

module ImageReader (
    input clk,
    input reset,
    input start,                    // Signal to begin reading image
    input next_pixel,               // Request from UART for next pixel
    
    // BRAM interface
    input [31:0] bram_data_out,     // 32-bit data from Block RAM
    output reg [19:0] bram_addr,    // Address to Block RAM
    
    // Output signals
    output reg [15:0] width,        // Image width (from location 0)
    output reg [15:0] height,       // Image height (from location 1)
    output reg [7:0] red,           // Red component of current pixel
    output reg [7:0] green,         // Green component of current pixel
    output reg [7:0] blue,          // Blue component of current pixel
    output reg valid,               // Pixel data valid
    output reg done                 // All pixels read
);

    localparam IDLE = 4'd0;
    localparam REQ_WIDTH = 4'd1;
    localparam WAIT_WIDTH = 4'd2;
    localparam REQ_HEIGHT = 4'd3;
    localparam WAIT_HEIGHT = 4'd4;
    localparam REQ_PIXEL = 4'd5;
    localparam WAIT_PIXEL = 4'd6;
    localparam OUTPUT_PIXEL = 4'd7;
    localparam FINISHED = 4'd8;

    localparam BRAM_READ_LATENCY = 2;

    reg [3:0] state;
    reg [2:0] wait_count;
    reg [31:0] pixel_count;
    reg [31:0] pixels_read;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            wait_count <= 3'd0;
            bram_addr <= 20'd0;
            width <= 16'd0;
            height <= 16'd0;
            red <= 8'd0;
            green <= 8'd0;
            blue <= 8'd0;
            valid <= 1'b0;
            done <= 1'b0;
            pixel_count <= 32'd0;
            pixels_read <= 32'd0;
        end else begin
            valid <= 1'b0;

            case (state)
                IDLE: begin
                    done <= 1'b0;
                    pixels_read <= 32'd0;
                    if (start) begin
                        state <= REQ_WIDTH;
                    end
                end

                REQ_WIDTH: begin
                    bram_addr <= 20'd0;
                    wait_count <= BRAM_READ_LATENCY;
                    state <= WAIT_WIDTH;
                end

                WAIT_WIDTH: begin
                    if (wait_count != 0) begin
                        wait_count <= wait_count - 1'b1;
                    end else begin
                        width <= bram_data_out[15:0];
                        state <= REQ_HEIGHT;
                    end
                end

                REQ_HEIGHT: begin
                    bram_addr <= 20'd1;
                    wait_count <= BRAM_READ_LATENCY;
                    state <= WAIT_HEIGHT;
                end

                WAIT_HEIGHT: begin
                    if (wait_count != 0) begin
                        wait_count <= wait_count - 1'b1;
                    end else begin
                        height <= bram_data_out[15:0];
                        pixel_count <= width * bram_data_out[15:0];
                        pixels_read <= 32'd0;
                        state <= REQ_PIXEL;
                    end
                end

                REQ_PIXEL: begin
                    if (pixels_read < pixel_count) begin
                        bram_addr <= 20'd2 + pixels_read[19:0];
                        wait_count <= BRAM_READ_LATENCY;
                        state <= WAIT_PIXEL;
                    end else begin
                        state <= FINISHED;
                    end
                end

                WAIT_PIXEL: begin
                    if (wait_count != 0) begin
                        wait_count <= wait_count - 1'b1;
                    end else begin
                        state <= OUTPUT_PIXEL;
                    end
                end

                OUTPUT_PIXEL: begin
                    blue <= bram_data_out[23:16];
                    green <= bram_data_out[15:8];
                    red <= bram_data_out[7:0];
                    valid <= 1'b1;

                    if (next_pixel) begin
                        pixels_read <= pixels_read + 1'b1;
                        state <= REQ_PIXEL;
                    end
                end

                FINISHED: begin
                    done <= 1'b1;
                    if (!start) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
