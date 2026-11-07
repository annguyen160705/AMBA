onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {A channel} /tb_mem_axi/ACLK
add wave -noupdate -expand -group {A channel} /tb_mem_axi/ARESETn
add wave -noupdate -expand -group {W state} -radix hexadecimal /tb_mem_axi/dut/addrW
add wave -noupdate -expand -group {W state} /tb_mem_axi/dut/beatW
add wave -noupdate -expand -group {W state} /tb_mem_axi/dut/stateW
add wave -noupdate -expand -group {W channel} /tb_mem_axi/WID
add wave -noupdate -expand -group {W channel} -radix hexadecimal /tb_mem_axi/WDATA
add wave -noupdate -expand -group {W channel} /tb_mem_axi/WSTRB
add wave -noupdate -expand -group {W channel} /tb_mem_axi/WLAST
add wave -noupdate -expand -group {W channel} /tb_mem_axi/WVALID
add wave -noupdate -expand -group {W channel} /tb_mem_axi/WREADY
add wave -noupdate -expand -group {AW channel} /tb_mem_axi/AWID
add wave -noupdate -expand -group {AW channel} -radix hexadecimal /tb_mem_axi/AWADDR
add wave -noupdate -expand -group {AW channel} /tb_mem_axi/AWLEN
add wave -noupdate -expand -group {AW channel} /tb_mem_axi/AWLOCK
add wave -noupdate -expand -group {AW channel} /tb_mem_axi/AWSIZE
add wave -noupdate -expand -group {AW channel} /tb_mem_axi/AWBURST
add wave -noupdate -expand -group {AW channel} /tb_mem_axi/AWVALID
add wave -noupdate -expand -group {AW channel} /tb_mem_axi/AWREADY
add wave -noupdate -expand -group {AW local signals} /tb_mem_axi/dut/AWID_reg
add wave -noupdate -expand -group {AW local signals} /tb_mem_axi/dut/AWADDR_reg
add wave -noupdate -expand -group {AW local signals} /tb_mem_axi/dut/AWLEN_reg
add wave -noupdate -expand -group {AW local signals} /tb_mem_axi/dut/AWLOCK_reg
add wave -noupdate -expand -group {AW local signals} /tb_mem_axi/dut/AWSIZE_reg
add wave -noupdate -expand -group {AW local signals} /tb_mem_axi/dut/AWBURST_reg
add wave -noupdate -expand -group {AW local signals} /tb_mem_axi/dut/AWCACHE_reg
add wave -noupdate -expand -group {AW local signals} /tb_mem_axi/dut/AWPROT_reg
add wave -noupdate -expand -group {B channel} /tb_mem_axi/BID
add wave -noupdate -expand -group {B channel} /tb_mem_axi/BRESP
add wave -noupdate -expand -group {B channel} /tb_mem_axi/BVALID
add wave -noupdate -expand -group {B channel} /tb_mem_axi/BREADY
add wave -noupdate -expand -group {Tempo local signals} -radix hexadecimal /tb_mem_axi/dut/Twaddr
add wave -noupdate -expand -group {Tempo local signals} -radix hexadecimal /tb_mem_axi/dut/Twdata
add wave -noupdate -expand -group {Tempo local signals} /tb_mem_axi/dut/Twstrb
add wave -noupdate -expand -group {Tempo local signals} /tb_mem_axi/dut/Twen
add wave -noupdate -expand -group {Tempo local signals} /tb_mem_axi/dut/Traddr
add wave -noupdate -expand -group {Tempo local signals} /tb_mem_axi/dut/Trdata
add wave -noupdate -expand -group {Tempo local signals} /tb_mem_axi/dut/Trstrb
add wave -noupdate -expand -group {Tempo local signals} /tb_mem_axi/dut/Tren
add wave -noupdate -expand -group {Tempo local signals} /tb_mem_axi/dut/TrenX
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{STW_IDLE else} {20000 ps} 1} {send_aw {40000 ps} 1} {{local updates} {45000 ps} 1} {{AWVALID = 0} {50000 ps} 1} {{send word} {60000 ps} 1} {{local updates} {65000 ps} 1} {{Cursor 7} {70000 ps} 1} {receive_b {85000 ps} 1 Yellow Red} {{BREADY = 0} {90000 ps} 1} {send_aw {110000 ps} 1 default Yellow} {{local update} {115000 ps} 1 default Yellow} {{send beat0} {130000 ps} 1 default Yellow} {{receive beat0} {135000 ps} 1 default Yellow} {{send beat1} {150000 ps} 1 default Yellow} {{receive beat1} {155000 ps} 0} {{send beat2} {170000 ps} 1 default Yellow} {{receive beat2} {175000 ps} 1 default Yellow} {response {195000 ps} 1 default Yellow}
quietly wave cursor active 18
configure wave -namecolwidth 207
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
WaveRestoreZoom {0 ps} {290906 ps}
bookmark add wave bookmark0 {{18726 ps} {103924 ps}} 0
