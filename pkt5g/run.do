# Launch from this directory: vsim -do run.do
if {![file isdirectory work]} {vlib work}
vlog -sv pkt5g_pkg.sv tb_pkt5g.sv
vsim -t 1ps work.tb_pkt5g
add wave -radix hex /tb_pkt5g/*
run -all
