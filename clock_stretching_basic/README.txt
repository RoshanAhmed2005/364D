CLOCK STRETCHING BUILDING BLOCKS

Three independent SystemVerilog design modules. Add these .sv files as design
sources in Vivado. No testbenches or simulator scripts are included.

1. packet_source.sv
Configurable packet length, default 16 words. Each 32-bit word contains a
16-bit packet ID and a 16-bit word index. first and last mark packet boundaries.
A transfer occurs on a rising clk edge with valid && ready. If ready is low,
data and markers stay stable. enable starts packet production; lowering it
allows the current packet to finish. Packet IDs wrap after 65535.
WORDS_PER_PACKET must be 1 through 65536.
This produces synthetic streaming traffic; it does not implement a 5G protocol.

2. simple_fifo.sv
Configurable WIDTH and DEPTH, defaults 32 bits and 16 entries. Both sides use
valid/ready transfers. level reports stored words. A full FIFO can accept a
new word if a stored word is read on the same edge. out_data is the oldest
word and is meaningful only while out_valid is high. It remains stable under
output backpressure. Reset discards buffered words. DEPTH must be >= 2;
leave COUNT_BITS at its computed default. Non-power-of-two depths work too.
This is a SINGLE-clock FIFO; crossing clock domains requires a later async FIFO.

Connecting source to FIFO:
  Same clk and rst_n for both modules.
  source.data -> FIFO.in_data
  source.valid -> FIFO.in_valid
  FIFO.in_ready -> source.ready
  Consumer drives FIFO.out_ready and accepts FIFO.out_data when out_valid.
To preserve packet markers in the FIFO, use WIDTH=34 and connect
  FIFO.in_data = {source.first, source.last, source.data}
  At the output, unpack {first, last, data} from FIFO.out_data.

3. voltage_status.sv
Accepts a numerical millivolt sample on a rising clk edge when sample_valid
is high. The sample and sample_valid must already be synchronous to clk.
The output is registered and holds its last reading between samples.
status_valid becomes high after the first sample and stays high until reset.
Consumers must check status_valid before treating v_sense as a valid reading.

Default falling thresholds:
  Less than 980 mV -> minor droop (01)
  Less than 950 mV -> moderate droop (10)
  Less than 920 mV -> severe droop (11)
  Otherwise -> nominal (00)

Recovery uses 10 mV hysteresis. For example, 979 mV enters minor droop, but
982 mV does not clear it; recovery to 990 mV clears it. This prevents repeated
status changes when the input fluctuates near a threshold. All thresholds
and the recovery margin are module parameters.

droop_active is high whenever a valid reading is non-nominal. voltage_fault
reports a sampled value outside 900 through 1100 mV and clears on the next
in-range sample; it is separate from droop severity and is not a latched fault.
The values come from the draft project operating envelope, not characterized
safe limits. For custom parameters, keep the thresholds ordered and the
hysteresis margin smaller than the gaps between neighboring thresholds.

This is a digital monitoring interface for supplied voltage samples. Actual
voltage sensing, asynchronous sample capture, physical voltage-to-delay
behavior, clock generation, and CDC integration remain later project work.
