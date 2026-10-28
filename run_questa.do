# Alternate path for a lab already using Questa/ModelSim.
# Untested here. Launch from this directory: vsim -c -do run_questa.do
onerror {quit -code 1 -force}
if {![file isdirectory work]} {vlib work}
vlog -sv rtl/*.sv sim/*.sv tb/*.sv
foreach test {tb_voltage_clock tb_fifo tb_fifo_stress tb_slot_tick} {
    vsim -t 1ps work.$test
    run -all
    quit -sim
}
vsim -t 1ps work.tb_datapath +baseline
run -all
quit -sim
vsim -t 1ps work.tb_datapath
run -all
quit -sim
quit -code 0 -force
