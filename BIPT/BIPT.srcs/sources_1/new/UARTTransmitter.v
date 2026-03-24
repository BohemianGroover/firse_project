`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// UART Transmitter - Flow-controlled sender
// Sends image metadata and pixel data in format:
//   WIDTH:###
//   HEIGHT:###
//   R:###,G:###,B:###
//////////////////////////////////////////////////////////////////////////////////

module UARTTransmitter (
    input clk,                      
    input reset,
    input [15:0] width,             
    input [15:0] height,            
    input [7:0] red,
    input [7:0] green,
    input [7:0] blue,
    input pixel_valid,              
    input image_done,               
    
    output uart_tx,                 
    output ready_for_pixel          
);

    localparam BAUD_CYCLES = 32'd868;

    localparam ST_WAIT_PIXEL = 3'd0;
    localparam ST_SEND_WIDTH = 3'd1;
    localparam ST_SEND_HEIGHT = 3'd2;
    localparam ST_SEND_PIXEL = 3'd3;
    localparam ST_DONE = 3'd4;

    reg [2:0] state;
    reg [31:0] baud_clk;
    reg [3:0] bit_count;
    reg transmitting;
    reg [7:0] txdata;
    reg [5:0] char_index;
    reg metadata_sent;
    reg pixel_latched;
    reg [7:0] red_l, green_l, blue_l;

    function [7:0] digit_to_ascii(input [15:0] number, input [1:0] place);
        reg [15:0] d;
        begin
            case (place)
                2'd0: d = (number / 100) % 10;
                2'd1: d = (number / 10) % 10;
                default: d = number % 10;
            endcase
            digit_to_ascii = 8'h30 + d[7:0];
        end
    endfunction

    assign uart_tx = ~transmitting ? 1'b1 :
                     (bit_count == 0) ? 1'b0 :
                     (bit_count <= 8) ? txdata[bit_count-1] :
                     1'b1;

    assign ready_for_pixel = (state == ST_WAIT_PIXEL) && !pixel_latched && !transmitting;

    always @(posedge clk) begin
        if (reset) begin
            state <= ST_WAIT_PIXEL;
            baud_clk <= 32'd0;
            bit_count <= 4'd0;
            transmitting <= 1'b0;
            txdata <= 8'd0;
            char_index <= 6'd0;
            metadata_sent <= 1'b0;
            pixel_latched <= 1'b0;
            red_l <= 8'd0;
            green_l <= 8'd0;
            blue_l <= 8'd0;
        end else begin
            if (transmitting) begin
                if (baud_clk < BAUD_CYCLES - 1) begin
                    baud_clk <= baud_clk + 1;
                end else begin
                    baud_clk <= 32'd0;
                    bit_count <= bit_count + 1;
                    if (bit_count == 4'd9) begin
                        transmitting <= 1'b0;
                        bit_count <= 4'd0;
                    end
                end
            end else begin
                if (state == ST_WAIT_PIXEL) begin
                    if (pixel_valid && !pixel_latched) begin
                        red_l <= red;
                        green_l <= green;
                        blue_l <= blue;
                        pixel_latched <= 1'b1;
                        char_index <= 6'd0;
                        if (!metadata_sent) begin
                            state <= ST_SEND_WIDTH;
                        end else begin
                            state <= ST_SEND_PIXEL;
                        end
                    end else if (image_done && !metadata_sent) begin
                        // Ensure metadata is emitted even if no pixels were produced.
                        red_l <= 8'd0;
                        green_l <= 8'd0;
                        blue_l <= 8'd0;
                        pixel_latched <= 1'b0;
                        char_index <= 6'd0;
                        state <= ST_SEND_WIDTH;
                    end
                end else begin
                    case (state)
                        ST_SEND_WIDTH: begin
                            case (char_index)
                                0: txdata <= "W";
                                1: txdata <= "I";
                                2: txdata <= "D";
                                3: txdata <= "T";
                                4: txdata <= "H";
                                5: txdata <= ":";
                                6: txdata <= digit_to_ascii(width, 2'd0);
                                7: txdata <= digit_to_ascii(width, 2'd1);
                                8: txdata <= digit_to_ascii(width, 2'd2);
                                default: txdata <= 8'h0A;
                            endcase
                            transmitting <= 1'b1;
                            if (char_index == 6'd9) begin
                                char_index <= 6'd0;
                                state <= ST_SEND_HEIGHT;
                            end else begin
                                char_index <= char_index + 1'b1;
                            end
                        end

                        ST_SEND_HEIGHT: begin
                            case (char_index)
                                0: txdata <= "H";
                                1: txdata <= "E";
                                2: txdata <= "I";
                                3: txdata <= "G";
                                4: txdata <= "H";
                                5: txdata <= "T";
                                6: txdata <= ":";
                                7: txdata <= digit_to_ascii(height, 2'd0);
                                8: txdata <= digit_to_ascii(height, 2'd1);
                                9: txdata <= digit_to_ascii(height, 2'd2);
                                default: txdata <= 8'h0A;
                            endcase
                            transmitting <= 1'b1;
                            if (char_index == 6'd10) begin
                                char_index <= 6'd0;
                                metadata_sent <= 1'b1;
                                state <= ST_SEND_PIXEL;
                            end else begin
                                char_index <= char_index + 1'b1;
                            end
                        end

                        ST_SEND_PIXEL: begin
                            case (char_index)
                                0: txdata <= "R";
                                1: txdata <= ":";
                                2: txdata <= digit_to_ascii({8'd0, red_l}, 2'd0);
                                3: txdata <= digit_to_ascii({8'd0, red_l}, 2'd1);
                                4: txdata <= digit_to_ascii({8'd0, red_l}, 2'd2);
                                5: txdata <= ",";
                                6: txdata <= "G";
                                7: txdata <= ":";
                                8: txdata <= digit_to_ascii({8'd0, green_l}, 2'd0);
                                9: txdata <= digit_to_ascii({8'd0, green_l}, 2'd1);
                                10: txdata <= digit_to_ascii({8'd0, green_l}, 2'd2);
                                11: txdata <= ",";
                                12: txdata <= "B";
                                13: txdata <= ":";
                                14: txdata <= digit_to_ascii({8'd0, blue_l}, 2'd0);
                                15: txdata <= digit_to_ascii({8'd0, blue_l}, 2'd1);
                                16: txdata <= digit_to_ascii({8'd0, blue_l}, 2'd2);
                                default: txdata <= 8'h0A;
                            endcase
                            transmitting <= 1'b1;
                            if (char_index == 6'd17) begin
                                char_index <= 6'd0;
                                pixel_latched <= 1'b0;
                                if (image_done) begin
                                    state <= ST_DONE;
                                end else begin
                                    state <= ST_WAIT_PIXEL;
                                end
                            end else begin
                                char_index <= char_index + 1'b1;
                            end
                        end

                        ST_DONE: begin
                            if (!image_done) begin
                                state <= ST_WAIT_PIXEL;
                            end
                        end

                        default: begin
                            state <= ST_WAIT_PIXEL;
                        end
                    endcase
                end
            end
        end
    end

endmodule



