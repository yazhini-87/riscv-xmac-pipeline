## Clock 100MHz - Arty A7
set_property PACKAGE_PIN E3      [get_ports clk]
set_property IOSTANDARD  LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

## Reset - Button BTN0
set_property PACKAGE_PIN C2      [get_ports rst]
set_property IOSTANDARD  LVCMOS33 [get_ports rst]

## Debug LEDs
set_property PACKAGE_PIN H5      [get_ports {debug_leds[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {debug_leds[0]}]
set_property PACKAGE_PIN J5      [get_ports {debug_leds[1]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {debug_leds[1]}]
set_property PACKAGE_PIN T9      [get_ports {debug_leds[2]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {debug_leds[2]}]
set_property PACKAGE_PIN T10     [get_ports {debug_leds[3]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {debug_leds[3]}]

## Debug valid signal - LED4
set_property PACKAGE_PIN R3      [get_ports debug_valid]
set_property IOSTANDARD  LVCMOS33 [get_ports debug_valid]