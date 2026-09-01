vlog rtl/*.sv
vlog tb/*.sv
verilator --lint-only --Wall rtl/fixed_priority_arbiter.sv
verilator --lint-only --Wall rtl/priority_arbiter.sv

vsim work.priority_arbiter_tb

add wave sim:/priority_arbiter_tb/clk
add wave sim:/priority_arbiter_tb/arstn
add wave sim:/priority_arbiter_tb/REQ
add wave sim:/priority_arbiter_tb/GNT

run -all