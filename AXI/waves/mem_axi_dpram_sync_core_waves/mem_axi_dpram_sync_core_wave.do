onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_mem_axi_dpram_sync_core/dut/RESETn
add wave -noupdate -expand -group tb_read_signals /tb_mem_axi_dpram_sync_core/raddr
add wave -noupdate -expand -group tb_read_signals /tb_mem_axi_dpram_sync_core/rdata
add wave -noupdate -expand -group tb_read_signals /tb_mem_axi_dpram_sync_core/ren
add wave -noupdate -expand -group tb_write_signals /tb_mem_axi_dpram_sync_core/waddr
add wave -noupdate -expand -group tb_write_signals /tb_mem_axi_dpram_sync_core/wdata
add wave -noupdate -expand -group tb_write_signals /tb_mem_axi_dpram_sync_core/wen
add wave -noupdate -expand -group write_block_signals /tb_mem_axi_dpram_sync_core/dut/WADDR
add wave -noupdate -expand -group write_block_signals /tb_mem_axi_dpram_sync_core/dut/WDATA
add wave -noupdate -expand -group write_block_signals /tb_mem_axi_dpram_sync_core/dut/WEN
add wave -noupdate -expand -group read_block_signals /tb_mem_axi_dpram_sync_core/dut/RADDR
add wave -noupdate -expand -group read_block_signals /tb_mem_axi_dpram_sync_core/dut/RDATA
add wave -noupdate -expand -group read_block_signals /tb_mem_axi_dpram_sync_core/dut/REN
add wave -noupdate {/tb_mem_axi_dpram_sync_core/dut/mem[16]}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {52606 ps}
