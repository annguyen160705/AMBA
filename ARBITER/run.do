vlog rtl/*.sv
vlog tb/*.sv
verilator --lint-only --Wall rtl/fixed_priority_arbiter.sv
vsim work.fixed_priority_arbiter_tb