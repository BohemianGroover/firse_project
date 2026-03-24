`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.03.2026
// Design Name: 
// Module Name: TopLevel
// Project Name: BIPT - FPGA Image Processing
// Target Devices: Nexys4 DDR (xc7a100tcsg324-1)
// Description: Top-level integration of complete image processing pipeline
//              Reads image from BRAM -> Processes -> Transmits via UART
//
//////////////////////////////////////////////////////////////////////////////////

module TopLevel (
    input clk,                      // 100MHz clock
    input reset,                    // Active high reset
    input [2:0] sel_module,         // Mode selection
    input [7:0] val,                // Brightness adjustment value
    input start,                    // Start processing signal
    
    // UART output
    output uart_tx,
    
    // Status/Control outputs
    output done,
    output ready
);

    // Internal BRAM interface signals
    wire [31:0] bram_data_out;
    wire [19:0] bram_addr;
    
    // Internal signals
    wire [15:0] img_width;
    wire [15:0] img_height;
    wire [7:0] raw_red, raw_green, raw_blue;
    wire pixel_valid;
    wire reader_done;
    
    wire [7:0] proc_red, proc_green, proc_blue;
    wire proc_done_in, proc_done_out;
    
    wire uart_ready;
    
    // State machine for overall control
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam COMPLETE = 2'b10;
    
    reg [1:0] state, next_state;
    reg auto_start;
    
    // Block RAM IP Instantiation (generated from Vivado IP Catalog)
    // Read-only mode: tie off write signals
blk_mem_gen_0 bram_inst (
    .clka(clk),
    .addra(bram_addr),
    .douta(bram_data_out)
);
    
    // Module instantiations
    
    // 1. ImageReader - Reads image from Block RAM
    ImageReader image_reader (
        .clk(clk),
        .reset(reset),
        .start(state == PROCESSING),
        .next_pixel(uart_ready),
        .bram_data_out(bram_data_out),
        .bram_addr(bram_addr),
        .width(img_width),
        .height(img_height),
        .red(raw_red),
        .green(raw_green),
        .blue(raw_blue),
        .valid(pixel_valid),
        .done(reader_done)
    );
    
    // 2. Modules - Process pixels based on sel_module
    // Note: Modules has internal red/green/blue test values, doesn't use input ports
    Modules image_processor (
        .clk(clk),
        .reset(reset),
        .sel_module(sel_module),
        .val(val),
        .done_in(pixel_valid),  // Pixel ready
        .red(raw_red),
        .green(raw_green),
        .blue(raw_blue),
        .red_o(proc_red),
        .green_o(proc_green),
        .blue_o(proc_blue),
        .done_out(proc_done_out)
    );
    
    // 3. UARTTransmitter - Output via UART
    UARTTransmitter uart_tx_module (
        .clk(clk),
        .reset(reset),
        .width(img_width),
        .height(img_height),
        .red(proc_red),
        .green(proc_green),
        .blue(proc_blue),
        .pixel_valid(proc_done_out),
        .image_done(reader_done),
        .uart_tx(uart_tx),
        .ready_for_pixel(uart_ready)
    );
    
    // State machine
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            auto_start <= 1'b1;
        end else begin
            state <= next_state;
            if (state == PROCESSING)
                auto_start <= 1'b0;
        end
    end
    
    always @(*) begin
        case (state)
            IDLE: begin
                if (start || auto_start)
                    next_state = PROCESSING;
                else
                    next_state = IDLE;
            end
            
            PROCESSING: begin
                if (reader_done)
                    next_state = COMPLETE;
                else
                    next_state = PROCESSING;
            end
            
            COMPLETE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Output assignments
    assign ready = (state == IDLE);
    assign done = (state == COMPLETE);

endmodule
