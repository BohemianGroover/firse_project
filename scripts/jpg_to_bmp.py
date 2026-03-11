"""
Converts any image (JPG, PNG, etc.) to a 24-bit uncompressed BMP
suitable for use in the BIPT Vivado simulation testbench.

Requirements:
  - Width must be divisible by 4 (BMP row padding rule)
  - Must be 24-bit color (no alpha channel)
  - File size must fit within testbench ARRAY_LEN (default ~512 KB)
    If image is large, it will be resized to fit.

Usage:
  python scripts/jpg_to_bmp.py <input_image> <output_bmp>

Example:
  python scripts/jpg_to_bmp.py C:/Users/yawal/Desktop/input.jpg C:/Users/yawal/Desktop/input_converted.bmp
"""

import os
import sys
import cv2
import argparse


MAX_FILE_SIZE_BYTES = 500 * 1024  # Must match ARRAY_LEN in tb_modules.v (~512 KB)
BYTES_PER_PIXEL = 3               # 24-bit BMP = 3 bytes per pixel
BMP_HEADER_SIZE = 54              # Standard BMP header is 54 bytes


def jpg_to_bmp(input_path: str, output_path: str) -> None:
    """
    Loads any image and saves it as a 24-bit uncompressed BMP.
    - Ensures width is divisible by 4
    - Resizes if the file would exceed MAX_FILE_SIZE_BYTES
    - Prints image info before and after conversion
    """
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"Input image not found: '{input_path}'")

    img = cv2.imread(input_path)
    if img is None:
        raise ValueError(f"Could not read image: '{input_path}'. "
                         "Ensure it is a valid JPG/PNG/BMP file.")

    orig_h, orig_w = img.shape[:2]
    print(f"Input : {input_path}")
    print(f"  Size    : {orig_w} x {orig_h} pixels")
    print(f"  Format  : {os.path.splitext(input_path)[1].upper()}")

    # --- Resize if too large for testbench ARRAY_LEN ---
    max_pixels = (MAX_FILE_SIZE_BYTES - BMP_HEADER_SIZE) // BYTES_PER_PIXEL
    total_pixels = orig_w * orig_h

    if total_pixels > max_pixels:
        import math
        scale = math.sqrt(max_pixels / total_pixels)
        new_w = int(orig_w * scale)
        new_h = int(orig_h * scale)
        print(f"  WARNING: Image too large for testbench ({total_pixels} pixels > {max_pixels} max).")
        print(f"  Resizing to {new_w} x {new_h} ...")
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_AREA)
        orig_h, orig_w = img.shape[:2]

    # --- Crop width to nearest multiple of 4 ---
    new_w = (orig_w // 4) * 4
    if new_w != orig_w:
        print(f"  Cropping width {orig_w} -> {new_w} (must be divisible by 4)")
        img = img[:, :new_w]

    final_h, final_w = img.shape[:2]
    estimated_size = BMP_HEADER_SIZE + final_w * final_h * BYTES_PER_PIXEL

    # --- Ensure output directory exists ---
    out_dir = os.path.dirname(output_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    # --- Write as 24-bit BMP ---
    success = cv2.imwrite(output_path, img)
    if not success:
        raise IOError(f"Failed to write BMP to: '{output_path}'")

    actual_size = os.path.getsize(output_path)
    print(f"\nOutput: {output_path}")
    print(f"  Size    : {final_w} x {final_h} pixels")
    print(f"  File    : {actual_size:,} bytes")
    print(f"  Ready for Vivado simulation: YES")
    print(f"\nNext step: Update read_fileName in tb_modules.v to point to this BMP.")


def main():
    parser = argparse.ArgumentParser(
        description="Convert any image to a 24-bit BMP valid for BIPT Vivado simulation.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("input_image", type=str,
                        help="Path to the input image (JPG, PNG, BMP, etc.)")
    parser.add_argument("output_bmp", type=str,
                        help="Path for the output .bmp file")
    args = parser.parse_args()

    try:
        jpg_to_bmp(args.input_image, args.output_bmp)
    except FileNotFoundError as e:
        print(f"File Error: {e}")
        sys.exit(1)
    except ValueError as e:
        print(f"Image Error: {e}")
        sys.exit(1)
    except IOError as e:
        print(f"Write Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
