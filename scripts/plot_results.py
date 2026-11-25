#!/usr/bin/env python3
# Makes two bar charts from simulation/trace_results.csv
# Needs:  pip3 install matplotlib
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

names, hit_rate, amat = [], [], []
with open("simulation/trace_results.csv") as f:
    for row in csv.DictReader(f):
        names.append(row["trace"])
        hit_rate.append(float(row["hit_rate_percent"]))
        amat.append(float(row["amat_cycles"]))

fig, ax = plt.subplots(1, 2, figsize=(11, 4))
ax[0].bar(names, hit_rate)
ax[0].set_title("Read hit rate per trace")
ax[0].set_ylabel("hit rate (%)")
ax[1].bar(names, amat)
ax[1].set_title("AMAT per trace")
ax[1].set_ylabel("cycles")
for a in ax:
    a.tick_params(axis="x", rotation=30)
plt.tight_layout()
plt.savefig("simulation/trace_results.png", dpi=150)
print("saved simulation/trace_results.png")
