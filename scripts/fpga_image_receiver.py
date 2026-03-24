#!/usr/bin/env python3
"""
Receives image data from FPGA via UART and reconstructs + displays it.

Protocol:
1. First line: WIDTH:###
2. Second line: HEIGHT:###
3. Following lines: R:###,G:###,B:### (one per pixel)

The script reads these values, creates an image buffer dynamically,
fills it with pixel data, and displays/saves the result.
"""

import serial
import sys
import time
from PIL import Image
import argparse
import re
from pathlib import Path

def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Receive and display FPGA-processed images via UART"
    )
    parser.add_argument(
        "--port",
        type=str,
        default=None,
        help="Serial port (e.g., COM5, /dev/ttyUSB0). Auto-detect if not specified."
    )
    parser.add_argument(
        "--baud",
        type=int,
        default=115200,
        help="Baud rate (default: 115200)"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="Serial read timeout in seconds (default: 30)"
    )
    parser.add_argument(
        "--metadata-wait",
        type=int,
        default=90,
        help="Max seconds to wait for WIDTH/HEIGHT metadata (default: 90)"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="output_image.png",
        help="Output file for processed image"
    )
    parser.add_argument(
        "--save-all",
        action="store_true",
        help="Save all 8 processing modes"
    )
    parser.add_argument(
        "--raw-log",
        type=str,
        default=None,
        help="Optional path to save all incoming UART lines"
    )
    parser.add_argument(
        "--from-log",
        type=str,
        default=None,
        help="Reconstruct image from a previously captured UART log file"
    )
    return parser.parse_args()


def find_serial_port():
    """Auto-detect and return available serial port."""
    try:
        import serial.tools.list_ports
        ports = list(serial.tools.list_ports.comports())
        if not ports:
            print("No serial ports found!")
            return None
        
        print("Available serial ports:")
        for i, port in enumerate(ports):
            print(f"  {i}: {port.device} - {port.description}")
        
        # Use first available (most likely the FPGA)
        selected_port = ports[0].device
        print(f"\nUsing port: {selected_port}")
        return selected_port
    except ImportError:
        print("pyserial-tools not available. Specify port manually.")
        return None


def open_serial(port, baud, timeout):
    """Open serial connection."""
    try:
        ser = serial.Serial(port, baud, timeout=timeout)
        print(f"Connected to {port} at {baud} baud")
        return ser
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}")
        return None


def parse_pixel_line(line):
    """Parse one pixel line in form R:###,G:###,B:###."""
    match = re.search(r"R\s*:\s*(\d+)\s*,\s*G\s*:\s*(\d+)\s*,\s*B\s*:\s*(\d+)", line)
    if not match:
        return None

    r = max(0, min(255, int(match.group(1))))
    g = max(0, min(255, int(match.group(2))))
    b = max(0, min(255, int(match.group(3))))
    return (r, g, b)


def reconstruct_from_log(log_path):
    """Parse a UART text log and reconstruct image data offline."""
    path = Path(log_path)
    if not path.exists():
        print(f"[!] Log file not found: {path}")
        return None, None, None

    lines = path.read_text(errors='ignore').splitlines()
    if not lines:
        print("[!] Log file is empty")
        return None, None, None

    width = None
    height = None
    start_index = 0

    for i, raw_line in enumerate(lines):
        line = raw_line.strip()
        if width is None:
            width_match = re.search(r"WIDTH\s*:\s*(\d+)", line)
            if width_match:
                width = int(width_match.group(1))
                continue

        if height is None:
            height_match = re.search(r"HEIGHT\s*:\s*(\d+)", line)
            if height_match:
                height = int(height_match.group(1))
                start_index = i + 1
                break

    if width is None or height is None:
        print("[!] Could not find WIDTH/HEIGHT in log file")
        return None, None, None

    expected_pixels = width * height
    image_data = []

    for line in lines[start_index:]:
        pixel = parse_pixel_line(line.strip())
        if pixel is None:
            continue
        image_data.append(pixel)
        if len(image_data) >= expected_pixels:
            break

    print(f"[*] Log metadata: {width}x{height} ({expected_pixels} pixels)")
    print(f"[*] Parsed pixels from log: {len(image_data)}/{expected_pixels}")
    return width, height, image_data


def read_metadata(ser, metadata_wait=90, raw_log_handle=None):
    """Read WIDTH and HEIGHT from FPGA, tolerating empty/noisy serial lines."""
    print("\n[*] Reading image metadata...")
    print("    Waiting for FPGA UART stream. Press the START button now.")

    width = None
    height = None
    deadline = time.time() + metadata_wait
    last_status_print = 0

    while time.time() < deadline:
        raw = ser.readline()
        if not raw:
            now = time.time()
            if now - last_status_print >= 5:
                remaining = int(deadline - now)
                print(f"    Still waiting for metadata... ({remaining}s left)")
                last_status_print = now
            continue

        line = raw.decode('utf-8', errors='ignore').strip()
        if raw_log_handle is not None:
            raw_log_handle.write(line + "\n")
        if not line:
            continue

        # Helpful for debugging unexpected UART payloads.
        print(f"    Received: {line}")

        width_match = re.search(r"WIDTH\s*:\s*(\d+)", line)
        if width_match:
            width = int(width_match.group(1))
            continue

        height_match = re.search(r"HEIGHT\s*:\s*(\d+)", line)
        if height_match:
            height = int(height_match.group(1))

        if width is not None and height is not None:
            print(f"    Image size: {width}x{height} ({width * height} pixels)")
            return width, height

    print(f"    ERROR: Metadata timeout after {metadata_wait}s")
    print("    Did not receive both WIDTH and HEIGHT from FPGA.")
    return None, None


def read_pixels(ser, width, height, raw_log_handle=None):
    """Read all pixels from FPGA and reconstruct image."""
    print(f"\n[*] Reading {width * height} pixels...")
    
    image_data = []
    expected_pixels = width * height
    pixels_received = 0
    
    start_time = time.time()
    
    try:
        for pixel_index in range(expected_pixels):
            # Read pixel line
            pixel_line = ser.readline().decode('utf-8', errors='ignore').strip()
            if raw_log_handle is not None:
                raw_log_handle.write(pixel_line + "\n")
            
            if not pixel_line:
                print(f"    Timeout or empty line at pixel {pixel_index + 1}/{expected_pixels}")
                break
            
            # Parse "R:###,G:###,B:###"
            try:
                parts = pixel_line.split(',')
                if len(parts) < 3:
                    print(f"    WARNING: Invalid pixel format at {pixel_index + 1}: {pixel_line}")
                    continue
                
                r = int(parts[0].split(':')[1])
                g = int(parts[1].split(':')[1])
                b = int(parts[2].split(':')[1])
                
                # Clamp to valid range
                r = max(0, min(255, r))
                g = max(0, min(255, g))
                b = max(0, min(255, b))
                
                image_data.append((r, g, b))
                pixels_received += 1
                
                # Progress indicator
                if (pixel_index + 1) % (expected_pixels // 10 + 1) == 0:
                    elapsed = time.time() - start_time
                    percent = ((pixel_index + 1) / expected_pixels) * 100
                    print(f"    {percent:5.1f}% - {pixels_received} pixels received in {elapsed:.1f}s")
            
            except (ValueError, IndexError) as e:
                print(f"    WARNING: Could not parse pixel {pixel_index + 1}: {pixel_line}")
                print(f"    Error: {e}")
                continue
    
    except KeyboardInterrupt:
        print("\n[!] Interrupted by user")
    
    elapsed = time.time() - start_time
    print(f"\n[*] Reception complete: {pixels_received}/{expected_pixels} pixels in {elapsed:.1f}s")
    
    return image_data


def create_image(width, height, image_data):
    """Create PIL Image from pixel data."""
    if len(image_data) != width * height:
        print(f"[!] Warning: Expected {width*height} pixels, got {len(image_data)}")
        print(f"[!] Image may be incomplete.")
    
    # Create new RGB image
    image = Image.new('RGB', (width, height))
    pixels = image.load()
    
    # Fill pixels
    for idx, (r, g, b) in enumerate(image_data):
        y = idx // width
        x = idx %width
        pixels[x, y] = (r, g, b)
    
    return image


def main():
    args = parse_args()
    
    print("=" * 60)
    print("FPGA Image Receiver - BIPT Project")
    print("=" * 60)
    
    # Offline mode: rebuild from previously captured log file.
    if args.from_log is not None:
        width, height, image_data = reconstruct_from_log(args.from_log)
        if width is None or height is None or not image_data:
            sys.exit(1)

        print(f"\n[*] Creating image...")
        image = create_image(width, height, image_data)

        print(f"[*] Displaying image...")
        image.show()

        output_path = Path(args.output)
        image.save(str(output_path))
        print(f"[*] Image saved to: {output_path.resolve()}")
        print("\n[+] Success!")
        return

    # Live serial mode.
    if args.port is None:
        args.port = find_serial_port()
        if args.port is None:
            print("[!] Could not auto-detect serial port. Specify with --port")
            sys.exit(1)

    ser = open_serial(args.port, args.baud, args.timeout)
    if ser is None:
        sys.exit(1)
    
    try:
        raw_log_handle = None
        if args.raw_log is not None:
            raw_log_path = Path(args.raw_log)
            raw_log_path.parent.mkdir(parents=True, exist_ok=True)
            raw_log_handle = raw_log_path.open("w", encoding="utf-8")
            print(f"[*] Logging raw UART to: {raw_log_path.resolve()}")

        # Clear any stale bytes before waiting for a fresh frame.
        ser.reset_input_buffer()

        # Read metadata
        width, height = read_metadata(ser, args.metadata_wait, raw_log_handle)
        if width is None or height is None:
            print("[!] Failed to read image metadata")
            sys.exit(1)
        
        # Read pixels
        image_data = read_pixels(ser, width, height, raw_log_handle)
        
        if not image_data:
            print("[!] No pixel data received")
            sys.exit(1)
        
        # Create image
        print(f"\n[*] Creating image...")
        image = create_image(width, height, image_data)
        
        # Display image
        print(f"[*] Displaying image...")
        image.show()
        
        # Save image
        output_path = Path(args.output)
        image.save(str(output_path))
        print(f"[*] Image saved to: {output_path.resolve()}")
        
        print("\n[+] Success!")
    
    except Exception as e:
        print(f"\n[!] Error: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        try:
            if 'raw_log_handle' in locals() and raw_log_handle is not None:
                raw_log_handle.close()
        except Exception:
            pass
        if ser and ser.isOpen():
            ser.close()
            print("[*] Serial connection closed")


if __name__ == "__main__":
    main()
