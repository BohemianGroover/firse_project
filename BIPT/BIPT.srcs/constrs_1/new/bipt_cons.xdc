## Nexys 4 DDR Constraints File for BIPT Project
## Reference: Nexys4 DDR Rev. C
## IMPORTANT: Ensure project device is set to: xc7a100tcsg324-1
## NOTE: This design uses UART output only, no direct LED outputs

## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }]

## UART TX Output (for sending processed images to PC)
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; #USB-RS232 TX

## Reset Button (BTNC - Center button)
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 PULLTYPE PULLDOWN } [get_ports { reset }]

## Start Signal (BTNC - can use same or different button, using BTNU for now)
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 PULLTYPE PULLDOWN } [get_ports { start }]

## Mode Selection Switches (sel_module[2:0])
## Using SW[0], SW[1], SW[2]
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { sel_module[0] }]
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { sel_module[1] }]
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { sel_module[2] }]

## Brightness Value Input (val[7:0])
## Using SW[3] through SW[10]
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { val[0] }]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { val[1] }]
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { val[2] }]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { val[3] }]
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { val[4] }]
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports { val[5] }]
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS18 } [get_ports { val[6] }]
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { val[7] }]

## Done Output Signal (using LED16 - LD16 red channel)
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { done }]

## Ready Output Signal (using LED17 - LD17 red channel)
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { ready }]
