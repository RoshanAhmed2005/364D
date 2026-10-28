#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
command -v iverilog >/dev/null || { echo 'Install Icarus Verilog (iverilog and vvp), then retry.' >&2; exit 1; }
command -v vvp >/dev/null || { echo 'vvp is missing.' >&2; exit 1; }
rtl=(rtl/*.sv)
iverilog -g2012 -Wall -s tb_voltage_clock -o build/voltage.vvp "${rtl[@]}" sim/*.sv tb/tb_voltage_clock.sv
vvp build/voltage.vvp
iverilog -g2012 -Wall -s tb_fifo -o build/fifo.vvp "${rtl[@]}" tb/tb_fifo.sv
vvp build/fifo.vvp
for ratio in '5 7' '7 3' '4 4'; do
    read -r wr rd <<< "$ratio"
    iverilog -g2012 -Wall -s tb_fifo_stress -Ptb_fifo_stress.WR_HALF="$wr" -Ptb_fifo_stress.RD_HALF="$rd" -o build/stress.vvp "${rtl[@]}" tb/tb_fifo_stress.sv
    vvp build/stress.vvp
done
iverilog -g2012 -Wall -s tb_slot_tick -o build/slot.vvp "${rtl[@]}" tb/tb_slot_tick.sv
vvp build/slot.vvp
iverilog -g2012 -Wall -s tb_datapath -o build/datapath.vvp "${rtl[@]}" sim/*.sv tb/tb_datapath.sv
vvp build/datapath.vvp +baseline
vvp build/datapath.vvp +waves
vvp build/datapath.vvp +baseline +nostalls
vvp build/datapath.vvp +nostalls
