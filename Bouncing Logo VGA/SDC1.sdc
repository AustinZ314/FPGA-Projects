set_time_format -unit ns -decimal_places 3

create_clock -add -name sys_clk_pin -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk}]