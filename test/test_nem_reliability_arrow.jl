nem_reliability_data_dir = joinpath(@__DIR__, "../..", "NEM-reliability-suite")
include("test_run_simulation.jl")
@testset "NEM reliability data - Arrow" verbose = true begin
    if isdir(nem_reliability_data_dir)
        _, _, timings = test_run_simulation(
            joinpath(nem_reliability_data_dir, "data", "arrow"),
            joinpath(nem_reliability_data_dir, "data", "arrow", "schedule-1w"),
            "arrow",
        )
        all_timings["NEM-Arrow"] = timings
    else
        @test_skip "NEM reliability data directory not found"
    end
end
