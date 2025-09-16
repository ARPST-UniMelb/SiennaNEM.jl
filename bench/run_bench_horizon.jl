using SiennaNEM
using DataFrames
using Dates
include("bench_horizon.jl")

# --- Input paths ---
const DATA_DIR = "data/nem12-arrow"
const TS_DIR = joinpath(DATA_DIR, "schedule-1w")

# --- Run benchmarks ---
println("Running horizon benchmarks...")
results = bench_horizon_all(
    DATA_DIR, TS_DIR;
    horizons=[Hour(6), Hour(12), Hour(24), Hour(48), Hour(96), Hour(168)],
    samples=1, seconds=5
)

# --- Build summary table ---
summary = DataFrame(
    HorizonHours=Int[],
    Operation=String[],
    MedianMs=Float64[]
)

for (h, group) in results
    h_hrs = Int(round(Dates.value(h) / 3600))  # convert to hours

    # Individual operations
    for op in ["model", "build", "solve"]
        time_ms = median(group[op]).time / 1_000_000
        push!(summary, (h_hrs, op, round(time_ms, digits=2)))
    end

    # Total = sum of medians
    total_ms = (
        median(group["model"]).time +
        median(group["build"]).time +
        median(group["solve"]).time
    ) / 1_000_000
    push!(summary, (h_hrs, "total", round(total_ms, digits=2)))
end

println(summary)
