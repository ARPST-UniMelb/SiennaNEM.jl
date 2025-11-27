using Dates

# NOTE:
#   This script require `uc_build_problem.jl` to be run first to setup the
# system. This script sets up and solves a single time unit decision model.

horizon = Hour(24)
add_ts!(sys, data; scenario_name=scenario_name)

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
