onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_mem_axi/dut/ARESETn
add wave -noupdate /tb_mem_axi/dut/ACLK
add wave -noupdate /tb_mem_axi/dut/stateR
add wave -noupdate -radix hexadecimal /tb_mem_axi/dut/dataR
add wave -noupdate -radix hexadecimal /tb_mem_axi/dut/addrR
add wave -noupdate /tb_mem_axi/dut/strbR
add wave -noupdate /tb_mem_axi/dut/beatR
add wave -noupdate -expand -group dp_ram -radix hexadecimal {/tb_mem_axi/dut/Udpram/mem_core[0]/Udpram_sync_core/mem}
add wave -noupdate -expand -group dp_ram -radix hexadecimal {/tb_mem_axi/dut/Udpram/mem_core[1]/Udpram_sync_core/mem}
add wave -noupdate -expand -group dp_ram -radix hexadecimal {/tb_mem_axi/dut/Udpram/mem_core[2]/Udpram_sync_core/mem}
add wave -noupdate -expand -group dp_ram -radix hexadecimal {/tb_mem_axi/dut/Udpram/mem_core[3]/Udpram_sync_core/mem}
add wave -noupdate -expand -group AR_channel /tb_mem_axi/dut/ARID
add wave -noupdate -expand -group AR_channel -radix hexadecimal /tb_mem_axi/dut/ARADDR
add wave -noupdate -expand -group AR_channel /tb_mem_axi/dut/ARLEN
add wave -noupdate -expand -group AR_channel /tb_mem_axi/dut/ARLOCK
add wave -noupdate -expand -group AR_channel /tb_mem_axi/dut/ARSIZE
add wave -noupdate -expand -group AR_channel /tb_mem_axi/dut/ARBURST
add wave -noupdate -expand -group AR_channel /tb_mem_axi/dut/ARVALID
add wave -noupdate -expand -group AR_channel /tb_mem_axi/dut/ARREADY
add wave -noupdate -expand -group R_channel /tb_mem_axi/dut/RID
add wave -noupdate -expand -group R_channel -radix hexadecimal /tb_mem_axi/dut/RDATA
add wave -noupdate -expand -group R_channel /tb_mem_axi/dut/RRESP
add wave -noupdate -expand -group R_channel /tb_mem_axi/dut/RVALID
add wave -noupdate -expand -group R_channel /tb_mem_axi/dut/RLAST
add wave -noupdate -expand -group R_channel /tb_mem_axi/dut/RREADY
add wave -noupdate -expand -group AR_reg_channel -radix hexadecimal /tb_mem_axi/dut/ARADDR_reg
add wave -noupdate -expand -group AR_reg_channel /tb_mem_axi/dut/ARLEN_reg
add wave -noupdate -expand -group AR_reg_channel /tb_mem_axi/dut/ARLOCK_reg
add wave -noupdate -expand -group AR_reg_channel /tb_mem_axi/dut/ARSIZE_reg
add wave -noupdate -expand -group AR_reg_channel /tb_mem_axi/dut/ARBURST_reg
add wave -noupdate -expand -group AR_reg_channel /tb_mem_axi/dut/ARCACHE_reg
add wave -noupdate -expand -group AR_reg_channel /tb_mem_axi/dut/ARPROT_reg
add wave -noupdate -expand -group Tempo -radix hexadecimal /tb_mem_axi/dut/Traddr
add wave -noupdate -expand -group Tempo -radix hexadecimal /tb_mem_axi/dut/Trdata
add wave -noupdate -expand -group Tempo /tb_mem_axi/dut/Trstrb
add wave -noupdate -expand -group Tempo /tb_mem_axi/dut/Tren
add wave -noupdate -expand -group Tempo /tb_mem_axi/dut/TrenX
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {send_ar {220000 ps} 1} {send_ar {280000 ps} 1 default Yellow} {{master(tb) send RREADY} {300000 ps} 1} {{RREADY & RVALID} {305000 ps} 0}
quietly wave cursor active 4
configure wave -namecolwidth 258
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {200958 ps} {368371 ps}
