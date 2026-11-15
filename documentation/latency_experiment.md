# Memory Latency Experiment

## 1. Goal

The goal of this experiment is to study how main memory read latency affects the Average Memory Access Time (AMAT) of a direct-mapped cache.

The main_memory module uses a configurable READ_LATENCY parameter to control the number of clock cycles before mem_ready is asserted after a read request.

The default READ_LATENCY value is 1, which represents the original behavior.

## 2. Method

The same cache testbench (cache_tb.v) was executed four times with different memory read latency values:

- READ_LATENCY = 1
- READ_LATENCY = 2
- READ_LATENCY = 4
- READ_LATENCY = 8

The following command was used:

```bash
for L in 1 2 4 8; do
  iverilog -DMEM_READ_LATENCY=$L -o sim rtl/*.v testbench/cache_tb.v &&
  vvp sim > simulation/latency_L$L.txt
done
```

The output files are:

- simulation/latency_L1.txt
- simulation/latency_L2.txt
- simulation/latency_L4.txt
- simulation/latency_L8.txt

## 3. Results

| READ_LATENCY (cycles) | Hit latency | Read miss latency | Miss penalty | Read miss rate | AMAT (cycles) | Checks |
|---:|---:|---:|---:|---:|---:|---|
| 1 | 4 | 7 | 3 | 57.45% | 5.723404 | 103 passed |
| 2 | 4 | 8 | 4 | 57.45% | 6.297872 | 103 passed |
| 4 | 4 | 10 | 6 | 57.45% | 7.446809 | 103 passed |
| 8 | 4 | 14 | 10 | 57.45% | 9.744681 | 103 passed |

AMAT is calculated using:

AMAT = Hit Time + (Read Miss Rate × Miss Penalty)

## 4. Analysis

- Hit latency remains constant at 4 cycles because a cache hit does not require accessing main memory.
- Read miss latency increases as READ_LATENCY increases.
- Read miss latency follows the relationship: 6 + READ_LATENCY.
- Read miss rate remains constant at approximately 57.45% because changing memory speed does not change which addresses hit or miss.
- AMAT increases from 5.723404 cycles to 9.744681 cycles as memory latency increases from 1 to 8 cycles.
- A slower main memory increases the cost of cache misses, making cache performance more important.

All four experiments completed successfully with 103 checks passed and 0 failed.

## 5. Module Notes

### cache_data_ram

- Contains 64 cache lines, each storing 128 bits.
- Uses a 6-bit index to select a cache line.
- Read data is registered and updated on the rising clock edge.
- During a write, the new write_data also appears on read_data.
- Data RAM is not initialized. The valid bit prevents the cache from using an invalid line.

### main_memory

- Contains 256 blocks of 128 bits each, giving a total capacity of 4 KB.
- Only block_address[7:0] is used to select a memory block.
- READ_LATENCY controls the delay before mem_ready is asserted for a read.
- Write operations update memory and assert mem_ready without waiting for the read latency parameter.

## 6. Tests Performed

### Data RAM Testbench

The following cases were verified:

- Write and read back data.
- Check independent cache lines.
- Verify write_enable = 0.
- Overwrite an existing line.
- Test first and last cache lines.
- Verify new write data appears on read_data during a write.

### Main Memory Testbench

The following cases were verified:

- Initial memory values are zero.
- Write and read back data.
- Verify independent memory blocks.
- Verify address aliasing using block_address[7:0].
- Measure read latency for different READ_LATENCY values.