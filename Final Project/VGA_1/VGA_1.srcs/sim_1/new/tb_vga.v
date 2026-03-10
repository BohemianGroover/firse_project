`timescale 1ns / 1ps

module tb_vga();

    // Clock and Reset signals
    reg clock;
    reg reset;
    reg [7:0] val;
    reg [3:0] sel_module;
    
    // Output signals
    wire hsync, vsync;
    wire [3:0] red, green, blue;
    
    // File handle
    integer pixel_file;
    integer cycle_count;
    integer non_zero_pixels;
    
    // Instantiate DUT
    vga_syncIndex uut (
        .clock(clock),
        .reset(reset),
        .val(val),
        .sel_module(sel_module),
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue)
    );
    
    // Clock generation - 100 MHz (10 ns period)
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end
    
    // Initialize file
    initial begin
        pixel_file = $fopen("simulation_pixels.txt", "w");
        if (pixel_file == 0) begin
            $display("ERROR: Cannot open file!");
            $finish;
        end
        
        cycle_count = 0;
        non_zero_pixels = 0;
        
        $fwrite(pixel_file, "=== VGA GRAYSCALE IMAGE SIMULATION ===\n");
        $fwrite(pixel_file, "Target: Display grayscale image from BRAM\n");
        $fwrite(pixel_file, "Mode: 0000 (Grayscale Conversion)\n");
        $fwrite(pixel_file, "============================================\n");
        $fwrite(pixel_file, "Cyc | Time(ns) | Rst | Mode | Val | HS | VS | R    | G    | B    | RGB_Hex\n");
        $fwrite(pixel_file, "============================================\n");
        $fflush(pixel_file);
        
        $display("=== Simulation Initialized ===");
        $display("File: simulation_pixels.txt opened");
        $display("Running for 50 milliseconds (50,000,000 ns)");
        $display("This allows multiple VGA frames to be displayed");
    end
    
    // Capture data on EVERY clock cycle
    always @(posedge clock) begin
        cycle_count = cycle_count + 1;
        
        // Write EVERY cycle
        $fwrite(pixel_file, "%3d | %8t | %b | %04b | %2d | %b  | %b  | %04b | %04b | %04b | #%h\n",
                cycle_count, $time, reset, sel_module, val, hsync, vsync, 
                red, green, blue, {red,green,blue});
        
        // Track non-zero RGB pixels
        if (red != 0 || green != 0 || blue != 0) begin
            non_zero_pixels = non_zero_pixels + 1;
        end
        
        // Flush every 1000 cycles and print console updates
        if (cycle_count % 1000 == 0) begin
            $fflush(pixel_file);
            if (cycle_count % 10000 == 0) begin
                $display("Cycle %d @ %t ns | RGB=(%04b,%04b,%04b) | Non-zero pixels found: %d", 
                         cycle_count, $time, red, green, blue, non_zero_pixels);
            end
        end
    end
    
    // Main stimulus  
    initial begin
        // Initialize inputs
        reset = 1;
        val = 0;
        sel_module = 4'b0000;  // Grayscale mode
        
        $display("\n--- PHASE 0: RESET ---");
        $fwrite(pixel_file, "\nPHASE 0: RESET\n");
        $fflush(pixel_file);
        
        #500;  // Hold reset for 500 ns
        
        // Release reset and start simulation
        reset = 0;
        
        $display("\n--- PHASE 1: ACTIVE GRAYSCALE SIMULATION ---");
        $display("Reset released at time 500ns");
        $display("Mode: 0000 (Grayscale)");
        $display("Waiting for VGA to reach active display area...");
        $fwrite(pixel_file, "\nPHASE 1: ACTIVE SIMULATION - GRAYSCALE MODE\n");
        $fflush(pixel_file);
        
        // 50 MILLION nanoseconds = 50 milliseconds
        // At 100 MHz: 50,000,000 ns allows ~3 full VGA frames (each frame ~16.7 ms)
        // VGA 800x600@60Hz = 40 MHz pixel clock = 25 ns per pixel
        // Full frame needs: ~800*600*25ns = ~12 ms
        #50000000;
        
        // End simulation
        $fwrite(pixel_file, "\n============================================\n");
        $fwrite(pixel_file, "SIMULATION ENDED\n");
        $fwrite(pixel_file, "Total Clock Cycles: %d\n", cycle_count);
        $fwrite(pixel_file, "Non-Zero RGB Pixels: %d\n", non_zero_pixels);
        $fwrite(pixel_file, "Simulation Time: 50,000,000 ns (50 ms)\n");
        $fwrite(pixel_file, "============================================\n");
        $fflush(pixel_file);
        $fclose(pixel_file);
        
        $display("\n=== SIMULATION COMPLETE ===");
        $display("Total Cycles: %d", cycle_count);
        $display("Grayscale Pixels Captured: %d", non_zero_pixels);
        $display("Output: simulation_pixels.txt");
        
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("T=%t | Cyc=%d | Reset=%b | Mode=%04b | RGB=(%04b,%04b,%04b)",
                 $time, cycle_count, reset, sel_module, red, green, blue);
    end

endmodule