using Dates

# NOTE:
#   This script require `uc_build_problem.jl` to be run first to setup the
# system. This script sets up and solves a single time unit decision model. You
# can specify the start_date and horizon for the decision model.

# Parameters for the decision model
start_date = DateTime("2025-01-10T00:00:00")
horizon = Hour(48)

# Add time series data to the system
add_ts!(
    sys, data;
    scenario_name=scenario_name, start_date=start_date, horizon=horizon
)

# Create and solve the decision model
problem = DecisionModel(
    template_uc, sys;
    optimizer=solver,
    horizon=horizon,
)
build!(problem; output_dir=mktempdir())
solve!(problem)
res = OptimizationProblemResults(problem)

objective_value = get_objective_value(res)
