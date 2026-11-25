#!/bin/bash
# Run from the repository root:  bash scripts/run_traces.sh
# Compiles once, runs every trace, writes simulation/trace_results.csv
set -e
python3 scripts/gen_traces.py > /dev/null
iverilog -o sim rtl/*.v testbench/tb_trace.v
mkdir -p simulation
echo "trace,requests,reads,writes,read_hits,hit_rate_percent,amat_cycles" > simulation/trace_results.csv
for t in sequential conflict loop_1_5kb random_1kb random_4kb mixed_rw; do
  n=$(wc -l < traces/$t.hex | tr -d ' ')
  vvp sim +trace=traces/$t.hex +n=$n +name=$t | grep "^RESULT," | sed 's/^RESULT,//' >> simulation/trace_results.csv
done
cat simulation/trace_results.csv
