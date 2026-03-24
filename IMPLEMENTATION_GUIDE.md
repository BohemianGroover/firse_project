# BIPT FPGA Implementation - Final Setup & Synthesis Guide

## Summary of What We've Built

### Verilog Modules Created:
1. **ImageReader.v** - Reads image metadata (WIDTH/HEIGHT) and pixel data from Block RAM
2. **UARTTransmitter.v** - Transmits image data via UART at 115200 baud  
3. **TopLevel.v** - Orchestrates the complete pipeline
4. **Modules.v** (modified) - Image processing core (already existed)

### Python Scripts Created:
1. **fpga_image_receiver.py** - Receives images from FPGA via USB and displays them
2. **coe_generator_with_metadata.py** - Converts images to COE format with metadata headers

### Constraint File Updated:
- Added UART TX pin constraint (C4 for output)

---

## Next Steps in Vivado

### Step 1: Open Your BIPT Project
1. Launch Vivado
2. Open: `c:\Users\yawal\Desktop\Fpga based image toolkit\firse_project\BIPT\BIPT.xpr`

### Step 2: Add New Source Files
1. Right-click **Sources** panel → **Add Sources**
2. Click **Add Files**
3. Add these three new Verilog files:
   - `ImageReader.v` (new)
   - `UARTTransmitter.v` (new)
   - `TopLevel.v` (new)
4. Click **Finish**

### Step 3: Create Block RAM IP Core
This step creates the memory that stores your image:

1. Go to **IP Catalog** (right panel, or Tools → IP Catalog)
2. Search for: "Block Memory Generator"
3. Click and create new IP > **Vivado IP Catalog**
4. Configure:
   - **Memory Type:** Single Port RAM
   - **Write Width:** 96 (to match format: 72 padding + 24 BGR)
   - **Read Width:** 96
   - **Depth:** 614,402 (enough for 640×480 image + metadata)
   - **Load Init File:** Select your `.coe` file
5. Generate the IP
6. Add the `.coe` file with metadata using the Python script:
   ```bash
   cd c:\Users\yawal\Desktop\Fpga based image toolkit\firse_project\scripts
   python coe_generator_with_metadata.py <your_image.jpg> flower_meta.coe
   ```

### Step 4: Set TopLevel as Top Module
1. Right-click **TopLevel.v** in Sources → **Set as Top**
2. Verify in the Tcl console that TopLevel is now the top module

### Step 5: Review Constraints
1. Open: `BIPT.srcs/constrs_1/new/bipt_cons.xdc`
2. Verify UART TX constraint is present:
   ```
   set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]
   ```
3. Verify CLK and reset pins are defined
4. **Note:** Other ports (switches, LEDs, buttons) are optional for this test

### Step 6: Run Synthesis
1. Click **Synthesis** (left panel, or Run → Synthesis)
2. **Expected Result:** Should complete with 0 critical warnings
3. **Possible Warnings:** OK if they're about unused I/O or unimplemented pins

### Step 7: Run Implementation
1. Click **Implementation** after synthesis completes
2. **Expected Result:** Should complete without critical errors

### Step 8: Generate Bitstream  
1. Click **Generate Bitstream**
2. This creates the `.bit` file to program the FPGA

### Step 9: Program FPGA
1. Connect Nexys4 DDR via USB
2. Click **Open Hardware Manager**
3. Click **Open Target → Auto Connect**
4. Click **Program Device** and select your `.bit` file

---

## Testing Your Design

### Part A: Prepare Test Image
```bash
# Convert any image to COE with metadata
cd c:\Users\yawal\Desktop\Fpga based image toolkit\firse_project\scripts

# Example with 320×240 image
python coe_generator_with_metadata.py your_image.jpg flower_meta.coe
```

**Output:** `flower_meta.coe` with:
- Location 0: WIDTH value
- Location 1: HEIGHT value
- Location 2onwards: RGB pixel data (96-bit format)

### Part B: Load COE into Block RAM
1. In Vivado, when creating Block RAM IP:
   - Check **Load Init File**
   - Browse to your `.coe` file
   - Regenerate IP

### Part C: Run on FPGA & View on Computer
```bash
# On your computer, run the Python receiver script
cd c:\Users\yawal\Desktop\Fpga based image toolkit\firse_project\scripts
python fpga_image_receiver.py --port COM5 --output result.png

# Replace COM5 with your actual serial port if different
# The script will auto-detect if not specified
```

**Expected Output:**
- Serial terminal shows:
  ```
  WIDTH:320
  HEIGHT:240
  R:###,G:###,B:###
  ...
  ```
- Python script reconstructs and displays the processed image
- Image saved as `result.png` (or specified --output file)

---

## Troubleshooting

### Synthesis Error: "Unresolved Reference"
- **Cause:** Block RAM not instantiated properly
- **Fix:** Make sure ImageReader instantiation matches Block RAM port names in TopLevel.v

### "uart_tx is not a valid port"
- **Cause:** UART constraint not added
- **Fix:** Add this line to `bipt_cons.xdc`:
  ```
  set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]
  ```

### Python Script "No serial ports found"
- **Cause:** USB not connected or driver not installed
- **Fix:** 
  1. Check USB cable is connected to Nexys4
  2. Device appears in Device Manager as "USB Serial Port (COM5)" or similar
  3. Specify port manually: `python fpga_image_receiver.py --port COM5`

### Image received but looks corrupted
- **Cause:** Block RAM .coe file format incorrect
- **Fix:** Use the provided `coe_generator_with_metadata.py` script
  - It handles the WIDTH/HEIGHT header automatically

---

## File Locations Reference

```
Project Root: c:\Users\yawal\Desktop\Fpga based image toolkit\firse_project\

Sources:
- Modules.v (modified)                         → BIPT/BIPT.srcs/sources_1/new/
- ImageReader.v (NEW)                          → BIPT/BIPT.srcs/sources_1/new/
- UARTTransmitter.v (NEW)                      → BIPT/BIPT.srcs/sources_1/new/
- TopLevel.v (NEW)                             → BIPT/BIPT.srcs/sources_1/new/

Constraints:
- bipt_cons.xdc (updated)                      → BIPT/BIPT.srcs/constrs_1/new/

Scripts:
- fpga_image_receiver.py (NEW)                 → scripts/
- coe_generator_with_metadata.py (NEW)         → scripts/
```

---

## Next: Advanced Enhancements (After Getting it Working)

Once the basic system works, you can:

1. **Improve UART Output:** Enhance UARTTransmitter to send formatted text (WIDTH:###, etc.)
2. **Add Image Selection:** Create a testbench to try different images quickly
3. **Add Processing Mode Selection:** Use switch inputs to select sel_module modes
4. **VGA Display:** Add VGA output for real-time image display on monitor
5. **SD Card Support:** Load images from external SD card instead of ROM

---

## Questions?
If you encounter issues during synthesis or implementation, share:
1. The exact error message
2. Which step it fails on
3. The synthesize/implement console output

This will help diagnose and fix the problem!
