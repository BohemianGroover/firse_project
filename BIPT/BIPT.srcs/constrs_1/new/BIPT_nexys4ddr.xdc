##############################################################################
# Nexys 4 DDR Constraints File for BIPT Project
# Maps image processing module to hardware I/O
##############################################################################

##############################################################################
# Clock Signal (100 MHz)
##############################################################################
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }]

##############################################################################
# Reset Button (Center button on Nexys 4 DDR)
##############################################################################
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 PULLTYPE PULLDOWN } [get_ports { reset }]

##############################################################################
# Mode Selection Switches (sel_module[2:0])
# Using 3 slide switches to select image processing mode
# 000 - RGB to Grayscale

# 001 - Increase Brightness
# 010 - Decrease Brightness
# 011 - Color Inversion
# 100 - Remove Red
# 101 - Remove Green
# 110 - Remove Blue
# 111 - Original (pass-through)
##############################################################################
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { sel_module[0] }]
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { sel_module[1] }]
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { sel_module[2] }]

##############################################################################
# Brightness Value Input (val[7:0])
# Using 8 switches for brightness adjustment value (0-255)
##############################################################################
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { val[0] }]
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { val[1] }]
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { val[2] }]
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { val[3] }]
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { val[4] }]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { val[5] }]
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { val[6] }]
set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { val[7] }]

##############################################################################
# Input Color Signals (red[7:0], green[7:0], blue[7:0])
# For now, used in simulation/testbench mode
# Can be mapped to external ADC or color sensor inputs if available
##############################################################################
# Reserved for future external hardware connection
# set_property -dict { PACKAGE_PIN ... IOSTANDARD LVCMOS33 } [get_ports { red[0] }]
# ... (other color pins)

##############################################################################
# Done Input Signal
# External ready signal (can use button or external trigger)
##############################################################################
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { done_in }]

##############################################################################
# Output Color Signals (red_o[7:0], green_o[7:0], blue_o[7:0])
# Mapped to RGB LEDs for visual feedback
##############################################################################
# RGB LED 0 (LD16-18)
set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { red_o[0] }]
set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { green_o[0] }]
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { blue_o[0] }]

# RGB LED 1 (LD17-19)
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { red_o[1] }]
set_property -dict { PACKAGE_PIN R11   IOSTANDARD LVCMOS33 } [get_ports { green_o[1] }]
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { blue_o[1] }]

# Standard LEDs (LD0-15) for additional output
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { red_o[2] }]
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { green_o[2] }]
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { blue_o[2] }]

set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { red_o[3] }]
set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { green_o[3] }]
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { blue_o[3] }]

set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { red_o[4] }]
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { green_o[4] }]
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { blue_o[4] }]

set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { red_o[5] }]
set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 } [get_ports { green_o[5] }]
set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33 } [get_ports { blue_o[5] }]

set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { red_o[6] }]
set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33 } [get_ports { green_o[6] }]
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { blue_o[6] }]

set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports { red_o[7] }]
set_property -dict { PACKAGE_PIN E14   IOSTANDARD LVCMOS33 } [get_ports { green_o[7] }]
set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33 } [get_ports { blue_o[7] }]

##############################################################################
# Done Output Signal
# Status LED to indicate processing complete
##############################################################################
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { done_out }]

##############################################################################
# Optional: UART for debugging/status messages
##############################################################################
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }]
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in }]
