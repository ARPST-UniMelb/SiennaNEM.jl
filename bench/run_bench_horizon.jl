using SiennaNEM
using DataFrames
using Dates
using Plots
include("bench_horizon.jl")

# --- Input paths ---
const DATA_DIR = "data/nem12-arrow"
const TS_DIR = joinpath(DATA_DIR, "schedule-1w")

# --- Run benchmarks ---
println("Running horizon benchmarks...")
results = bench_horizon_all(
    DATA_DIR, TS_DIR;
    horizons=[Hour(6), Hour(12), Hour(24), Hour(48), Hour(96), Hour(167)],
    samples=1, seconds=5
)

# --- Build df table ---
df = DataFrame(
    HorizonHours=Int[],
    Operation=String[],
    MedianMs=Float64[]
)

for (h_hrs, group) in results
    # Individual operations
    for op in ["model", "build", "solve"]
        time_ms = median(group[op]).time / 1_000_000
        push!(df, (h_hrs, op, round(time_ms, digits=2)))
    end

    # Total = sum of medians
    total_ms = (
        median(group["model"]).time +
        median(group["build"]).time +
        median(group["solve"]).time
    ) / 1_000_000
    push!(df, (h_hrs, "total", round(total_ms, digits=2)))
end

# sort first
sort!(df, :HorizonHours)

ops = ["model", "build", "solve", "total"]
plots = []
for op in ops
    subdf = filter(:Operation => ==(op), df)
    p = plot(subdf.HorizonHours, subdf.MedianMs;
             xlabel="Horizon (hours)", ylabel="Median time (ms)",
             title=op, lw=2, marker=:circle,
             yscale=(op == "model" ? :identity : :log10))
    push!(plots, p)
end

plt = plot(plots..., layout=(2,2), size=(900,600))
display(plt)

df_stage = filter(:Operation => op -> op ∈ ["model", "build", "solve"], df)
df_wide = unstack(df_stage, :Operation, :MedianMs)

println(df_wide)
