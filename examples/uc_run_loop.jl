using Dates
using PowerSystems

# NOTE:
#   This script require `uc_build_problem.jl` to be run first to setup the
# system. This script sets up and solves a multiple time unit decision model by
# iterating over time window. You can specify the horizon, initial_time, and
# window_shift. If schedule_horizon is less than horizon used in add_ts!, the
# decision model will not run for the full horizon of time series data added to
# the system. That is, the last horizon - schedule_horizon hours of time series data
# will not be solved.

# Parameters for the decision model
schedule_horizon = Hour(24)  # must be lower than or equal to the horizon used in add_ts!
window_shift = Hour(24)

# Loop through each time slice (TODO: wrap this in a function)
res_dict = Dict{DateTime, OptimizationProblemResults}()
initial_times = collect(InfrastructureSystems.get_forecast_initial_times(sys.data))
minimum_initial_time = first(initial_times)  # replace with desired start time
maximum_initial_time = last(initial_times)
for initial_time_slice in minimum_initial_time:window_shift:maximum_initial_time
    # TODO: use Deterministic directly to avoid removing and adding
    # Create and solve the decision model with the current time slice
    problem = DecisionModel(
        template_uc, sys;
        optimizer=solver,
        horizon=schedule_horizon,  # must be lower than or equal to the horizon used in add_ts!
        initial_time=initial_time_slice,
    )
    build!(problem; output_dir=mktempdir())
    solve!(problem)
    res_dict[initial_time_slice] = OptimizationProblemResults(problem)
end
