using Dates

# NOTE:
#   This script sets up and solves a single time unit decision model. You can 
# specify the horizon (hours) and initial time (initial_time) for the decision
# model.

hours = Hour(24)
initial_time = minimum(data["demand_l_ts"][!, "date"])

problem = DecisionModel(
    template_uc, sys;
    optimizer=solver,
    horizon=hours,
    initial_time=initial_time,
)
build!(problem; output_dir=mktempdir())
solve!(problem)
res = OptimizationProblemResults(problem)

objective_value = get_objective_value(res)
