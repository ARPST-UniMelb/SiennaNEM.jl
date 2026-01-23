using Test
using Dates
using HiGHS

using PowerSystems
using PowerSimulations
using InfrastructureSystems

using SiennaNEM


function test_system_creation(system_data_dir::String, ts_data_dir::String, backend::String)
    """
    Helper function to test system creation from data directory.

    Args:
        system_data_dir: Path to system data directory
        ts_data_dir: Path to time series data directory
        backend: Backend type, "arrow" or "csv"
    """

    horizon = Hour(72)
    interval = Hour(24)
    scenario = 1
    simulation_output_folder = "sienna-files"
    simulation_name = "test_system_creation_$backend"
    simulation_steps = 2  # number of rolling horizon steps

    # Track timings
    timings = Dict{String, Float64}()

    # Read data
    data = nothing
    @testset "[$(backend)] Get data" verbose = true begin
        timings["get_data"] = @elapsed begin
            data = SiennaNEM.get_data(system_data_dir, ts_data_dir; file_format=backend)
            @test data !== nothing
        end
    end

    # Create system
    sys_sienna = nothing
    @testset "[$(backend)] Create system" verbose = true begin
        timings["create_system"] = @elapsed begin
            sys_sienna = SiennaNEM.create_system!(data)
            @test typeof(sys_sienna) <: PowerSystems.System
        end
    end

    # Add time series
    @testset "[$(backend)] Add time series" verbose = true begin
        timings["add_ts"] = @elapsed begin
            SiennaNEM.add_ts!(
                sys_sienna, data;
                horizon=horizon,
                interval=interval,
                scenario=scenario,
            )
            @test InfrastructureSystems.get_forecast_horizon(sys_sienna.data) == horizon
        end
    end

    # Build problem template
    template_uc = nothing
    @testset "[$(backend)] Build problem template" verbose = true begin
        timings["build_template"] = @elapsed begin
            template_uc = SiennaNEM.build_problem_base_uc()
            @test typeof(template_uc) <: PowerSimulations.ProblemTemplate
        end
    end

    # Run decision model loop
    @testset "[$(backend)] Run decision model loop" verbose = true begin
        timings["run_simulation"] = @elapsed begin
            decision_models = SiennaNEM.run_simulation(
                template_uc, sys_sienna;
                simulation_folder=simulation_output_folder,
                simulation_name=simulation_name,
                simulation_steps=simulation_steps,
                decision_model_kwargs=(
                    optimizer=optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.01),
                ),
            )
            @test typeof(decision_models) <: PowerSimulations.Simulation
        end
    end

    # Print timing summary
    total_time = sum(values(timings))
    println("\n=== Timing Summary for $(backend) ===")
    for (step, time) in sort(collect(timings), by=x->x[2], rev=true)
        println("  $step: $(round(time, digits=2))s ($(round(100*time/total_time, digits=1))%)")
    end
    println("  TOTAL: $(round(total_time, digits=2))s")
    println("=" ^ 40)

    return data, sys_sienna, timings
end

# Setup paths
nem_reliability_data_dir = joinpath(@__DIR__, "../..", "NEM-reliability-suite")
pisp_data_dir = joinpath(nem_reliability_data_dir, "data/pisp-datasets/out-ref4006-poe10")
all_timings = Dict{String, Dict{String, Float64}}()

# Test 1: NEM reliability data - Arrow
@testset "NEM reliability data - Arrow" verbose = true begin
    if isdir(nem_reliability_data_dir)
        _, _, timings = test_system_creation(
            joinpath(nem_reliability_data_dir, "data", "arrow"),
            joinpath(nem_reliability_data_dir, "data", "arrow", "schedule-1w"),
            "arrow",
        )
        all_timings["NEM-Arrow"] = timings
    else
        @test_skip "NEM reliability data directory not found"
    end
end

# Test 2: NEM reliability data - CSV
@testset "NEM reliability data - CSV" verbose = true begin
    if isdir(nem_reliability_data_dir)
        _, _, timings = test_system_creation(
            joinpath(nem_reliability_data_dir, "data", "csv"),
            joinpath(nem_reliability_data_dir, "data", "csv", "schedule-1w"),
            "csv",
        )
        all_timings["NEM-CSV"] = timings
    else
        @test_skip "NEM reliability data directory not found"
    end
end

# Test 3: PISP data - Arrow
@testset "PISP data - Arrow" verbose = true begin
    if isdir(pisp_data_dir)
        arrow_dir = joinpath(pisp_data_dir, "arrow")
        if isdir(arrow_dir)
            schedule_names = filter(
                name -> startswith(name, "schedule-"),
                readdir(arrow_dir)
            )
            if !isempty(schedule_names)
                _, _, timings = test_system_creation(
                    arrow_dir,
                    joinpath(arrow_dir, schedule_names[1]),
                    "arrow",
                )
                all_timings["PISP-Arrow"] = timings
            else
                @test_skip "No schedule directories found in PISP Arrow data"
            end
        else
            @test_skip "PISP Arrow data directory not found"
        end
    else
        @test_skip "PISP data directory not found"
    end
end

# Test 4: PISP data - CSV
@testset "PISP data - CSV" verbose = true begin
    if isdir(pisp_data_dir)
        csv_dir = joinpath(pisp_data_dir, "csv")
        if isdir(csv_dir)
            schedule_names = filter(
                name -> startswith(name, "schedule-"),
                readdir(csv_dir)
            )
            if !isempty(schedule_names)
                _, _, timings = test_system_creation(
                    csv_dir,
                    joinpath(csv_dir, schedule_names[1]),
                    "csv",
                )
                all_timings["PISP-CSV"] = timings
            else
                @test_skip "No schedule directories found in PISP CSV data"
            end
        else
            @test_skip "PISP CSV data directory not found"
        end
    else
        @test_skip "PISP data directory not found"
    end
end

# Print overall timing comparison
println("\n" * "=" ^ 60)
println("OVERALL TIMING COMPARISON")
println("=" ^ 60)
for (test_name, timings) in sort(collect(all_timings), by=x->sum(values(x[2])), rev=true)
    total = sum(values(timings))
    println("$test_name: $(round(total, digits=2))s")
end
