`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// tb_modules.v - Runs all 8 image processing operations and writes one BMP each
// Operations (sel_module):
//   000 - RGB to Grayscale
//   001 - Increase Brightness  (val=50)
//   010 - Decrease Brightness  (val=50)
//   011 - Color Inversion
//   100 - Remove Red  (keep GB)
//   101 - Remove Green (keep RB)
//   110 - Remove Blue  (keep RG)
//   111 - Original (pass-through)
//////////////////////////////////////////////////////////////////////////////////

module tb_modules();

    reg clk, reset, done_in;
    reg [2:0] sel_module;
    reg [7:0] val;
    reg [7:0] red, green, blue;
    wire done_out;
    wire [7:0] red_o, green_o, blue_o;

    // Output base directory
    `define OUT_DIR "C:\\Users\\yawal\\Desktop\\Fpga based image toolkit\\firse_project\\images_result\\"

    Modules tb(clk, reset, sel_module, red, green, blue,
               done_in, done_out,
               val,
               red_o, green_o, blue_o);

    `define read_fileName "C:\\Users\\yawal\\Desktop\\Fpga based image toolkit\\firse_project\\images\\input_converted.bmp"

    localparam ARRAY_LEN = 520*1024;  // 509850 bytes needed for 476x357 image
    reg [7:0] data[0:ARRAY_LEN];
    integer size, start_pos, width, height, bitcount;

    // ---- Read BMP header + pixel data ----
    task readBMP;
        integer fileID;
        begin
            fileID = $fopen(`read_fileName, "rb");
            $display("fileID = %d", fileID);
            if (fileID == 0) begin
                $display("ERROR: Cannot open input file. Check path.");
                $finish;
            end else begin
                $fread(data, fileID);
                $fclose(fileID);
                size      = {data[5],data[4],data[3],data[2]};
                start_pos = {data[13],data[12],data[11],data[10]};
                width     = {data[21],data[20],data[19],data[18]};
                height    = {data[25],data[24],data[23],data[22]};
                bitcount  = {data[29],data[28]};
                $display("size=%0d  start_pos=%0d  width=%0d  height=%0d  bits=%0d",
                          size, start_pos, width, height, bitcount);
                if (bitcount != 24)
                    $display("WARNING: Expected 24-bit BMP, got %0d-bit", bitcount);
                if (width % 4 != 0) begin
                    $display("ERROR: Image width must be divisible by 4");
                    $finish;
                end
            end
        end
    endtask

    // ---- Pixel result buffer ----
    localparam RESULT_ARRAY_LEN = 5000*1024;
    reg [7:0] result[0:RESULT_ARRAY_LEN-1];
    reg capturing;
    integer j;

    always @(posedge clk) begin
        if (capturing && done_out) begin
            result[j]   <= blue_o;
            result[j+1] <= green_o;
            result[j+2] <= red_o;
            j <= j + 3;
        end
    end

    // ---- Write result BMP to given file handle ----
    task writeBMP;
        input integer fid;
        integer k;
        begin
            for (k = 0; k < start_pos; k = k+1)
                $fwrite(fid, "%c", data[k]);
            for (k = start_pos; k < size; k = k+1)
                $fwrite(fid, "%c", result[k - start_pos]);
            $fclose(fid);
        end
    endtask

    // ---- Run one full pass for a given mode ----
    integer p, fid;

    task runMode;
        input [2:0] mode;
        input integer fid_in;
        begin
            capturing  = 0;
            j          = 0;
            sel_module = mode;
            reset      = 1;
            done_in    = 0;
            @(posedge clk); @(posedge clk);
            reset     = 0;
            capturing = 1;

            for (p = start_pos; p < size; p = p+3) begin
                red   = data[p+2];
                green = data[p+1];
                blue  = data[p];
                #10;
                done_in = 1;
            end
            done_in   = 0;
            // Wait enough cycles for last pixel to be captured
            @(posedge clk); @(posedge clk); @(posedge clk);
            capturing = 0;

            writeBMP(fid_in);
        end
    endtask

    always begin
        #5 clk = ~clk;
    end

    initial begin
        clk       = 1;
        reset     = 1;
        done_in   = 0;
        capturing = 0;
        sel_module = 3'b000;
        val       = 8'd50;
        red = 0; green = 0; blue = 0;
        j   = 0;

        readBMP;

        // 000 - Grayscale
        fid = $fopen({`OUT_DIR, "result_000_grayscale.bmp"}, "wb");
        runMode(3'b000, fid);
        $display("DONE: result_000_grayscale.bmp");

        // 001 - Increase Brightness (val=50)
        fid = $fopen({`OUT_DIR, "result_001_inc_brightness.bmp"}, "wb");
        runMode(3'b001, fid);
        $display("DONE: result_001_inc_brightness.bmp");

        // 010 - Decrease Brightness (val=50)
        fid = $fopen({`OUT_DIR, "result_010_dec_brightness.bmp"}, "wb");
        runMode(3'b010, fid);
        $display("DONE: result_010_dec_brightness.bmp");

        // 011 - Color Inversion
        fid = $fopen({`OUT_DIR, "result_011_invert.bmp"}, "wb");
        runMode(3'b011, fid);
        $display("DONE: result_011_invert.bmp");

        // 100 - Remove Red (keep Green+Blue)
        fid = $fopen({`OUT_DIR, "result_100_no_red.bmp"}, "wb");
        runMode(3'b100, fid);
        $display("DONE: result_100_no_red.bmp");

        // 101 - Remove Green (keep Red+Blue)
        fid = $fopen({`OUT_DIR, "result_101_no_green.bmp"}, "wb");
        runMode(3'b101, fid);
        $display("DONE: result_101_no_green.bmp");

        // 110 - Remove Blue (keep Red+Green)
        fid = $fopen({`OUT_DIR, "result_110_no_blue.bmp"}, "wb");
        runMode(3'b110, fid);
        $display("DONE: result_110_no_blue.bmp");

        // 111 - Original (pass-through)
        fid = $fopen({`OUT_DIR, "result_111_original.bmp"}, "wb");
        runMode(3'b111, fid);
        $display("DONE: result_111_original.bmp");

        $display("\nAll 8 images written to C:\\Users\\yawal\\Desktop\\");
        $stop;
    end

endmodule
