create_clock -name ACLK -period 10.0 [get_ports ACLK]

set_clock_uncertainty 0.1 [get_clocks ACLK]
