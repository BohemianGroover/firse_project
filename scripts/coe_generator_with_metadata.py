"""
Enhanced COE Generator with WIDTH/HEIGHT Metadata (32-bit Format)

This script converts an image to Xilinx COE format WITH metadata headers.
Each memory location is 32 bits (16 padding + 16 data):
- Location 0: WIDTH (16 padding bits + 16-bit width value)
- Location 1: HEIGHT (16 padding bits + 16-bit height value)
- Location 2+: Pixel data (8 padding + 8-bit B + 8-bit G + 8-bit R)

Usage:
    python coe_generator_with_metadata.py <input_image> <output_coe_file>

Example:
    python coe_generator_with_metadata.py flower.bmp flower_with_meta.coe
"""

import os
import cv2
import sys
from pathlib import Path


def image_to_coe_with_metadata(image_path, coe_path):
    """
    Convert image to COE with WIDTH/HEIGHT metadata (32-bit format).
    
    Args:
        image_path: Path to input image (BMP, PNG, JPG, etc.)
        coe_path: Output COE file path
    """
    
    # Read image
    img = cv2.imread(str(image_path))
    if img is None:
        print(f"ERROR: Could not read image: {image_path}")
        return False
    
    height, width = img.shape[:2]  # OpenCV gives height x width
    total_pixels = width * height
    
    print(f"Image size: {width}x{height} ({total_pixels} pixels)")
    
    # Convert image to COE lines
    coe_lines = []
    
    # Line 0: WIDTH (32 bits = 16 padding + 16-bit width)
    # Format: 16 zero bits + 16-bit width value
    width_bits = format(width & 0xFFFF, '016b')  # 16-bit binary (cap at 15 bits for 0-32767)
    width_line = '0' * 16 + width_bits
    coe_lines.append(width_line)
    print(f"Location 0 (WIDTH={width}): {width_line}")
    
    # Line 1: HEIGHT (32 bits = 16 padding + 16-bit height)
    height_bits = format(height & 0xFFFF, '016b')  # 16-bit binary
    height_line = '0' * 16 + height_bits
    coe_lines.append(height_line)
    print(f"Location 1 (HEIGHT={height}): {height_line}")
    
    # Lines 2 onwards: Pixel data (32 bits each)
    pixel_count = 0
    for y in range(height):
        for x in range(width):
            b, g, r = img[y, x][:3]  # OpenCV returns BGR
            
            # Create 32-bit value: 8 padding + 8B + 8G + 8R
            b_bits = format(int(b), '08b')
            g_bits = format(int(g), '08b')
            r_bits = format(int(r), '08b')
            
            pixel_line = '00000000' + b_bits + g_bits + r_bits  # 8 padding + BGR
            coe_lines.append(pixel_line)
            
            pixel_count += 1
            if (pixel_count % (total_pixels // 10 + 1)) == 0:
                print(f"  Processed {pixel_count}/{total_pixels} pixels")
    
    print(f"Total COE lines: {len(coe_lines)}")
    
    # Write COE file
    try:
        with open(coe_path, 'w') as f:
            f.write("memory_initialization_radix=2;\n")
            f.write("memory_initialization_vector=\n")
            
            for i, line in enumerate(coe_lines):
                if i == len(coe_lines) - 1:
                    # Last line ends with semicolon
                    f.write(f"{line};\n")
                else:
                    # Other lines end with comma
                    f.write(f"{line},\n")
        
        print(f"Successfully wrote COE file: {coe_path}")
        return True
    
    except IOError as e:
        print(f"ERROR: Could not write COE file: {e}")
        return False


def main():
    if len(sys.argv) < 3:
        print("Usage: python coe_generator_with_metadata.py <input_image> <output_coe>")
        print("\nExample:")
        print("  python coe_generator_with_metadata.py flower.bmp flower_meta.coe")
        sys.exit(1)
    
    input_image = sys.argv[1]
    output_coe = sys.argv[2]
    
    if not Path(input_image).exists():
        print(f"ERROR: Input image not found: {input_image}")
        sys.exit(1)
    
    success = image_to_coe_with_metadata(input_image, output_coe)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
