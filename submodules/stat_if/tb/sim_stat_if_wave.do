onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/clk
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/stat_flags
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/wr_stats
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/wr_sys_mon
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/cfmem_wb_cyc
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/cfmem_wb_stb
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/cfmem_wb_we
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/cfmem_wb_ack
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/cfmem_wb_addr
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/cfmem_wb_din
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/cfmem_wb_dout
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/RESET
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/TEMP
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/VCCINT
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/VCCAUX
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/ALARM
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/state
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/shift_reg
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/wr_stats_i
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/wr_sys_mon_i
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/counter
add wave -noupdate -group stat_if -expand /stat_if_tb/stat_if_1/sysmon_data_i
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/stats_adr
add wave -noupdate -group stat_if /stat_if_tb/stat_if_1/sysmon_adr
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/CLK
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/RESET
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/TEMP
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/VCCINT
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/VCCAUX
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/ALARM
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/BUSY
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/EOC
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/DRDY
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/DADDR
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/CHANNEL
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/Counter
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/DO
add wave -noupdate -group sys_mon_controller /stat_if_tb/stat_if_1/sys_mon_1/ALARM_i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8679270 ps} 0}
configure wave -namecolwidth 215
configure wave -valuecolwidth 168
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
WaveRestoreZoom {8551737 ps} {8732617 ps}
