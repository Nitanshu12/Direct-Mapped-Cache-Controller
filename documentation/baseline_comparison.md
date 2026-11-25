# Baseline Comparison: Cache vs No Cache

## 1. Goal
Show when the cache makes the system faster. The baseline (`nocache_top.v`) sends
every read directly to main memory. Both designs get the same 72 reads
(16 sequential, 6 conflict, 50 random inside 1 KB) and the same main-memory model.
The memory read latency L is changed with `-DMEM_READ_LATENCY=L`.

## 2. Results

| Memory latency L | Cache: total cycles | Cache: average | No cache: total cycles | No cache: average | Speed-up |
|---:|---:|---:|---:|---:|---:|
| 1  | 402  | 5.58  | 216  | 3.00  | 0.54 |
| 2  | 440  | 6.11  | 288  | 4.00  | 0.65 |
| 4  | 516  | 7.17  | 432  | 6.00  | 0.84 |
| 8  | 668  | 9.28  | 720  | 10.00 | 1.08 |
| 10 | 744  | 10.33 | 864  | 12.00 | 1.16 |
| 20 | 1124 | 15.61 | 1584 | 22.00 | 1.41 |
| 50 | 2264 | 31.44 | 3744 | 52.00 | 1.65 |

Speed-up = no-cache cycles / cache cycles. Raw outputs: `simulation/compare_L*.txt`.

## 3. Analysis
- A request without a cache takes L + 2 cycles. With the cache, 34 of the 72 reads
  hit (4 cycles each) and 38 miss (6 + L cycles each).
- Cache total = 34 x 4 + 38 x (6 + L) = 364 + 38 L cycles.
  No-cache total = 72 x (L + 2) = 144 + 72 L cycles.
- The two are equal at L = 220 / 34 = about 6.5 cycles. Below this the cache is
  slower, above it the cache is faster.
- With a fast memory (L = 1) the cache does not help: a hit already costs 4 cycles,
  more than a direct memory access (3 cycles).
- A real DRAM needs tens of cycles, so for L = 20 to 50 the cache is 1.4 to 1.65
  times faster on this workload.
- The speed-up depends on the hit rate (47% on this workload). A workload with more
  reuse gives a larger speed-up.

## 4. Conclusion
The cache pays off only when main memory is slower than about 6 to 7 cycles. In
our earlier experiments the memory model answered in 1 cycle, so the cache looked
slow there. That result is an effect of the memory model, not of the cache design.
