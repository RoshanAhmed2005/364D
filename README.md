# Clock Stretching Risk Reduction Starter

Small SystemVerilog examples for the Ericsson project. Start with the voltage
test and FIFO test, then run the packet-transfer demonstration.

## What is included

| File | Basic function |
| --- | --- |
| `rtl/packet_source.sv` | Sends numbered 32-bit words in short packets, with start/end markers. |
| `rtl/async_fifo.sv` | Buffers words between two clock domains; used for ingress and egress. |
| `rtl/voltage_status.sv` | Converts an integer millivolt input into the project's two-bit voltage status. |
| `rtl/stretch_request.sv` | Converts voltage status into a requested period of 4, 5, 6, or 8 quarter-period units. |
| `rtl/toy_workload.sv` | Applies a simple XOR operation so the checker can verify processed data. |
| `rtl/demo_datapath.sv` | Connects the source, two FIFOs, and processing stage. |
| `rtl/slot_tick.sv` | Generates a periodic one-cycle `slot_sync` pulse. |
| `sim/stretch_clock_model.sv` | Produces an ideal stretched clock for simulation only. |
| `tb/` | Five self-checking testbenches. |

The data path is: packet source, ingress FIFO, toy processing stage, egress
FIFO, output checker. The source and output checker use `src_clk`; the
processing stage uses `proc_clk`.

This is synthetic traffic with packet boundaries, not 3GPP packet formatting,
an actual modem, or Ericsson packet-processing IP. The XOR operation is only
a placeholder workload. It can later be replaced without changing the FIFO
interfaces.

## Run the examples

Install Icarus Verilog, which supplies `iverilog` and `vvp`. From this folder,
run the following in Bash (Linux, macOS with the tools installed, or WSL):

```bash
bash run.sh
```

The script stops if compilation or a test fails. It uses the supported
SystemVerilog subset selected by `-g2012`; this is not a demonstration of
full IEEE 1800-2023 tool compliance.

For the integrated demonstration alone, after running the script:

```bash
vvp build/datapath.vvp +baseline
vvp build/datapath.vvp +waves
vvp build/datapath.vvp +baseline +nostalls
vvp build/datapath.vvp +nostalls
```

The second command writes `build/datapath.vcd`, which a waveform viewer such
as GTKWave can open. Useful signals include `voltage_mv`, `v_sense`,
`src_clk`, `proc_clk`, `selected_mode`, `ingress_full`, `egress_full`,
`source_valid`, `source_ready`, `sink_valid`, `sink_ready`, and `data_out`.

An alternate `run_questa.do` is included for labs using Questa/ModelSim:

```text
vsim -c -do run_questa.do
```

That alternate script has not been tested here. Run and debug the examples
in the environment your TA selects before claiming a target-environment demo.

## Start with these two team activities

### Activity 1: Voltage input and clock response

**Risk:** The team has not yet demonstrated how voltage conditions will be
represented or how clock-period changes will be checked.

Run `tb_voltage_clock`. It supplies nominal, minor, moderate, and severe
voltage codes and checks the resulting requested clock periods. It also
checks threshold boundaries, an out-of-range flag, and the fixed-clock bypass.

**Pass condition:** Correct status codes and periods of 10, 12.5, 15, and
20 ns, followed by 10 ns operation with stretching disabled. Save the console
output and explain one waveform showing a voltage change and clock response.

This exercise checks the digital representation and an ideal clock model.
It does not establish that a real droop can be detected fast enough to prevent
a physical setup failure.

### Activity 2: FIFO and packet transfer

**Risk:** Slowing the processing clock may cause buffering, data-order, or
backpressure mistakes across clock domains.

Run `tb_fifo`, `tb_fifo_stress`, and `tb_datapath`. The first fills and drains
a small FIFO, checks blocked accesses, wraps its pointers, and resets it.
The stress test sends 1,000 words with pseudo-random requests at three clock
ratios. The integrated test sends 32 packets of 8 words each through two FIFOs
and a processing register, using fixed and adaptive clocks. It also forces
the output to pause so data must be buffered.

**Pass condition:** All 256 input words arrive exactly once, in order, with
the correct transformation and packet markers. Data remains stable while
stalled. The finite burst drains within a deliberately generous 512-source-
cycle demo window. Compare the run with `+nostalls` against its fixed-clock
version to see the effect of the slower processing clock.

Keep the test log and a waveform showing FIFO backpressure. The checks use
`$fatal` to stop on errors; they are not an exhaustive SVA or formal suite.

These are proposed team demonstrations for discussion with the TA and mentor.
Have them confirm how HDL activities count toward the required software
modules and the two team activities. They do not replace the separate
individual risk reduction assignment.

## Interfaces and values to understand

### Packet interface

Every transfer occurs on a rising edge when `valid && ready` is true. While
`valid && !ready`, the sender holds its word unchanged. The 34-bit FIFO word
contains `{sop, eop, data[31:0]}`. For packet 2, word 3, the source sends
`32'h0002_0003`. The workload XORs the data with `32'hA5A5_5A5A`; markers
are preserved. Packet numbers restart at zero on a new `start` pulse.

The source ignores `start` while busy. One start requests one finite burst;
do not silently discard a new slot in a final system. The integration test
manually supplies one start pulse and does not wire in the optional slot timer.

### Voltage input

| Integer millivolts | `v_sense` | Requested period |
| --- | --- | --- |
| 980 and above | `00` | 1.0 times nominal |
| 950 through 979 | `01` | 1.25 times nominal |
| 920 through 949 | `10` | 1.5 times nominal |
| Below 920 | `11` | 2.0 times nominal |

The nominal input is 1000 mV. A separate flag marks values outside 900 through
1100 mV. The half-open boundaries above resolve ambiguity at exactly 980,
950, and 920 mV in the project draft. They are demo choices to confirm, not
characterized safe voltage/frequency limits. The range flag does not stop the
clock or recover an out-of-range supply.

The input is a numerical model of voltage, not a physical analog voltage.
The starter has no analog sensor, voltage-dependent logic-delay model,
hysteresis, or validated sensor-to-controller CDC interface.

### Clocks, FIFO, and slot timing

The integration demo uses a 100 MHz source and an ideal processing clock with
10/12.5/15/20 ns periods for readable waveforms. The clock model holds its
high pulse at 5 ns and extends the low pulse. Mode is sampled at a rising
edge and sets the interval to the following rising edge. It is behavioral
test equipment, not a physical clock-generator implementation.

The FIFO defaults to depth 8. `ADDR_BITS` must be at least 2; depth is
`2**ADDR_BITS`. `wr_ready` stays low while full and `rd_valid` stays low
while empty. These are ordinary handshake states, not evidence of corruption.
Data is show-ahead and only meaningful when `rd_valid` is asserted. Use a
common reset for both domains; reset discards in-flight data. Reset release
is synchronized separately in each domain.

The optional slot timer defaults to 245,760 cycles, which corresponds to
0.5 ms only at 491.52 MHz. Its unit test overrides the interval to 8 cycles.
At 100 MHz, 0.5 ms would require 50,000 cycles. None of the accelerated tests
demonstrates real 5G slot processing throughput.

The packet source supports positive packet and word counts up to 65,536 each.
The provided integrated scoreboard is deliberately fixed to the default
32-by-8 burst; update the checker and demo deadline if changing those values.

## What the recorded metrics mean

`stalls` counts source cycles with `valid && !ready`. `max_latency_cycles`
measures from acceptance into the ingress FIFO to acceptance at the output,
in source cycles. `peak_outstanding` is total accepted-but-not-yet-returned
words across the whole path, not occupancy of a single FIFO.
`completion_cycles` is the source-cycle count after reset release when the
last output is accepted. See `VERIFICATION.txt` for the actual run.

## Scope of the results

The included RTL is intended to describe synthesizable digital functions;
synthesis has not been run. The files in `sim/` and `tb/` are simulation-only.
This package does not implement a silicon-safe generated clock, prove CDC
metastability behavior, recover time debt, measure silicon area or power,
or demonstrate the final report's 15% power savings, <1% stretching time,
2-cycle droop-response limit, 10 us recovery, or physical timing closure.
The voltage profile intentionally uses frequent droops as a functional stress
test. Backpressure lets this synthetic source pause; a real radio input may
not permit pauses, so buffer sizing and overload policies remain project work.

Before using the FIFO in hardware, review CDC constraints, Gray-pointer bus
skew, reset behavior, and dual-clock memory inference with your TA. A digital
simulation pass is not physical CDC signoff.

## References and project grounding

- The supplied `project definition final (1).pdf` provides the 32-bit data,
  two-bit voltage status, period multipliers, and 0.5 ms slot context. Demo
  clocks, packet contents, finite burst size, XOR work, and FIFO depth are
  starter choices rather than sponsor-validated operating limits.
- Icarus usage: https://steveicarus.github.io/iverilog/usage/
- The FIFO follows the standard synchronized Gray-pointer architecture
  described by Clifford E. Cummings in *Simulation and Synthesis Techniques
  for Asynchronous FIFO Design* (SNUG San Jose 2002), FIFO style #1.
  This implementation is newly written for this starter.
