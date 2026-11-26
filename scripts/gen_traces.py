#!/usr/bin/env python3
# Generates the memory-access trace files in traces/.
# Line format (9 hex digits): first digit = operation (0 = read, 1 = write),
# next 8 digits = 32-bit address. Writes use the data {4{address}}.
import random, os

random.seed(1)                      # fixed seed: same files every time
os.makedirs("traces", exist_ok=True)

def save(name, items):
    with open(f"traces/{name}.hex", "w") as f:
        for op, addr in items:
            f.write(f"{op:1x}{addr:08x}\n")
    print(f"{name:18s} {len(items):4d} requests")

# 1. sequential: 64 consecutive words (256 bytes)
save("sequential", [(0, 0x100 + 4 * i) for i in range(64)])

# 2. conflict: two addresses with the same index, alternating
save("conflict", [(0, 0x30 if i % 2 == 0 else 0x430) for i in range(40)])

# 3. loop: 4 passes over a 1.5 KB array, one read per 16-byte block
save("loop_1_5kb", [(0, 16 * b) for _ in range(4) for b in range(96)])

# 4. random reads in 1 KB (fits in the cache)
save("random_1kb", [(0, random.randrange(0, 0x400, 16)) for _ in range(200)])

# 5. random reads in 4 KB (4x bigger than the cache)
save("random_4kb", [(0, random.randrange(0, 0x1000, 16)) for _ in range(200)])

# 6. mixed: 70% reads, 30% writes in 2 KB
save("mixed_rw", [(0 if random.random() < 0.7 else 1, random.randrange(0, 0x800, 16)) for _ in range(200)])
