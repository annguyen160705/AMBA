onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_mem_axi_dpram_sync/CLK
add wave -noupdate -expand -group write -radix binary /tb_mem_axi_dpram_sync/WADDR
add wave -noupdate -expand -group write /tb_mem_axi_dpram_sync/WDATA
add wave -noupdate -expand -group write /tb_mem_axi_dpram_sync/WEN
add wave -noupdate -expand -group write -radix binary /tb_mem_axi_dpram_sync/WSTRB
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[3]/Udpram_sync_core/WDATA}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[2]/Udpram_sync_core/WDATA}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[1]/Udpram_sync_core/WDATA}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[0]/Udpram_sync_core/WDATA}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[0]/Udpram_sync_core/mem[4]}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[1]/Udpram_sync_core/mem[4]}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[2]/Udpram_sync_core/mem[4]}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[3]/Udpram_sync_core/mem[4]}
add wave -noupdate -expand -group read /tb_mem_axi_dpram_sync/RADDR
add wave -noupdate -expand -group read /tb_mem_axi_dpram_sync/REN
add wave -noupdate -expand -group read -radix binary /tb_mem_axi_dpram_sync/RSTRB
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[3]/Udpram_sync_core/RDATA}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[2]/Udpram_sync_core/RDATA}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[1]/Udpram_sync_core/RDATA}
add wave -noupdate {/tb_mem_axi_dpram_sync/dut/mem_core[0]/Udpram_sync_core/RDATA}
add wave -noupdate /tb_mem_axi_dpram_sync/RDATA
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {64948 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {0 ps} {222247 ps}
