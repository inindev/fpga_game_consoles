// USB probe clocks. The three domains only talk through req/ack handshakes.
create_clock -name sys_clk -period 37.037 [get_ports {sys_clk}]     // 27 MHz
create_clock -name clk12 -period 83.333 [get_nets {clk12}]          // 12 MHz
create_clock -name clk86 -period 11.574 [get_nets {clk86}]          // 86.4 MHz
set_clock_groups -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {clk12}] -group [get_clocks {clk86}]
