vlog rtl/APB_Memory.sv
vlog tb/APB_Memory_tb.sv

vsim work.APB_Memory_tb

add wave -divider "APB Signals"

add wave sim:/APB_Memory_tb/Pclk
add wave sim:/APB_Memory_tb/Prst
add wave sim:/APB_Memory_tb/Paddr
add wave sim:/APB_Memory_tb/Pselx
add wave sim:/APB_Memory_tb/Penable
add wave sim:/APB_Memory_tb/Pwrite
add wave sim:/APB_Memory_tb/Pwdata

add wave -divider "APB Outputs"

add wave sim:/APB_Memory_tb/Pready
add wave sim:/APB_Memory_tb/Pslverr
add wave sim:/APB_Memory_tb/Prdata
add wave sim:/APB_Memory_tb/temp

add wave -divider "FSM"

add wave sim:/APB_Memory_tb/dut/PRESENT_STATE
add wave sim:/APB_Memory_tb/dut/NEXT_STATE

add wave -divider "Memory"

add wave sim:/APB_Memory_tb/dut/mem

run -all