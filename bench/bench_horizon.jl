using BenchmarkTools
using SiennaNEM
using Dates
using PowerSystems
using PowerSimulations
using HydroPowerSimulations
using StorageSystemsSimulations
using HiGHS

"""
    bench_horizon_setup(data_dir, ts_dir)

Prepare system, template, and solver once.
Returns (template_uc, sys, solver).
"""
function bench_horizon_setup(data_dir::AbstractString, ts_dir::AbstractString)
    data = read_system_data(data_dir)
    read_ts_data!(data, ts_dir)

    sys = create_system!(data)
    add_ts!(sys, data, scenario_name=1)

    template_uc = ProblemTemplate()
    set_device_model!(template_uc, Line, StaticBranch)
    set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)
    set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
    set_device_model!(template_uc, RenewableNonDispatch, FixedOutput)
    set_device_model!(template_uc, PowerLoad, StaticPowerLoad)

    storage_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict(
            "reservation" => true,
            "energy_target" => true,
            "cycling_limits" => false,
            "regularization" => false,
        ),
        use_slacks=false,
    )
    set_device_model!(template_uc, storage_model)

    set_network_model!(
        template_uc,
        NetworkModel(NFAPowerModel; use_slacks=true),
    )

    solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

    return template_uc, sys, solver
end


"""
    bench_model(template_uc, sys, solver, horizon; samples=10, seconds=5)

Benchmark creation of a DecisionModel (no build or solve).
"""
function bench_model(template_uc, sys, solver, horizon; samples=10, seconds=5)
    bm = @benchmarkable DecisionModel($template_uc, $sys; optimizer=$solver, horizon=$horizon) samples=samples seconds=seconds
    return run(bm)
end


"""
    bench_build(problem; samples=10, seconds=5)

Benchmark the `build!` step only (not solve).
Takes a fresh DecisionModel as input.
"""
function bench_build(problem; samples=10, seconds=5)
    bm = @benchmarkable build!($problem; output_dir=mktempdir()) samples=samples seconds=seconds
    return run(bm)
end


"""
    bench_horizon(problem; samples=10, seconds=5)

Benchmark the `solve!` step for a prepared (built) DecisionModel.
"""
function bench_horizon(problem; samples=10, seconds=5)
    bm = @benchmarkable solve!($problem) samples=samples seconds=seconds
    return run(bm)
end


"""
    bench_horizon_all(data_dir, ts_dir; horizons=[Hour(6), Hour(12), Hour(24)], samples=10, seconds=5)

Run model, build, and solve benchmarks across horizons.
Returns Dict[horizon_hours => Dict("model"=>…, "build"=>…, "solve"=>…)].
"""
function bench_horizon_all(data_dir::AbstractString, ts_dir::AbstractString;
                           horizons=[Hour(6), Hour(12), Hour(24)],
                           samples=10, seconds=5)

    template_uc, sys, solver = bench_horizon_setup(data_dir, ts_dir)

    results = Dict{Int,Dict{String,Any}}()
    for h in horizons
        hrs = Int(Dates.value(h))
        println("Benchmarking horizon: $h")

        # model
        model_res = bench_model(template_uc, sys, solver, h; samples=samples, seconds=seconds)

        # build
        problem = DecisionModel(template_uc, sys; optimizer=solver, horizon=h)
        build_res = bench_build(problem; samples=samples, seconds=seconds)

        # solve
        build!(problem; output_dir=mktempdir())
        solve_res = bench_horizon(problem; samples=samples, seconds=seconds)

        results[hrs] = Dict(
            "model" => model_res,
            "build" => build_res,
            "solve" => solve_res,
        )
    end

    return results
end
