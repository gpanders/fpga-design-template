# Define primary, virtual, and generated clocks here
create_clock -period 10 -name sys_clk [get_ports CLK] ; # 100 MHz system clock

