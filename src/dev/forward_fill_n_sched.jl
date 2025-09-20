using SiennaNEM
using DataFrames
using CSV
using Dates

function forward_fill!(df, exclude_cols=[:date])
    for col_name in names(df)
        if !(col_name in exclude_cols)
            col_values = df[!, col_name]
            last_valid = col_values[1]  # Start with first value
            
            for i in 2:length(col_values)
                if ismissing(col_values[i])
                    col_values[i] = last_valid
                else
                    last_valid = col_values[i]  # Update last valid value
                end
            end
        end
    end
end

system_data_dir = "data/nem12/arrow"
ts_data_dir = joinpath(system_data_dir, "schedule-1w")
data = read_system_data(system_data_dir)
read_ts_data!(data, ts_data_dir)

df_bus = data["bus"]
df_generator = data["generator"]
df_line = data["line"]
df_demand = data["demand"]
df_storage = data["storage"]

df_demand_l_ts = data["demand_l_ts"]
df_generator_pmax_ts = data["generator_pmax_ts"]
df_generator_n_ts = data["generator_n_ts"]
df_der_p_ts = data["der_p_ts"]
df_storage_emax_ts = data["storage_emax_ts"]
df_storage_lmax_ts = data["storage_lmax_ts"]
df_storage_n_ts = data["storage_n_ts"]
df_storage_pmax_ts = data["storage_pmax_ts"]
df_line_tmax_ts = data["line_tmax_ts"]
df_line_tmin_ts = data["line_tmin_ts"]

# NOTE:
# Sienna does'nt support change of emax and lmax, we need to add that as extra constraints straight to JuMP data
# Sienna also does'nt support change of n, that is number of available unit
# When we add constraints to JuMP model, check first is the timeseries data changes or not

# data
df_static = df_generator
id_col = "id_gen"

# static_col_ref = "n"
# df_ts = df_generator_n_ts

static_col_ref = "pmax"
df_ts = df_generator_pmax_ts

# scenario
scenario = 1

# star and end
# to debug n
# target_datetime = DateTime("2024-02-01T00:00:00")
# columns_to_check = ["date", "1", "84", "69"]
# date_start = DateTime(2024, 1, 1)
# date_end = DateTime(2025, 1, 1)

# to debug pmax
target_datetime = DateTime("2044-06-30T00:00:00")
columns_to_check = ["date", "78", "79"]
date_start = DateTime(2044, 6, 28)
date_end = DateTime(2044, 7, 2)

# initial data
id_col_val = string.(df_static[!, id_col])
static_col_ref_val = df_static[!, static_col_ref]
df_init = DataFrame(Dict(zip(id_col_val, static_col_ref_val)))

# NOTE: I haven't test the select last before selected
df_ts_before_selected = filter(
    row -> row.date < date_start && row.scenario == scenario,
    df_ts
)

# update df_init with df_ts_before_selected
if nrow(df_ts_before_selected) > 0
    # get latest on before date
    df_ts_before_selected = combine(groupby(df_ts_before_selected, id_col)) do group
        subset(group, :date => x -> x .== maximum(x))
    end

    # update init using latest
    ids_update = string.(df_ts_before_selected[!, id_col])
    gen_values_update = df_ts_before_selected.value
    df_init[1, ids_update] .= gen_values_update
end

# pre-allocate df
date_range = collect(date_start:Hour(1):date_end)
df_ts_out = DataFrame(date=date_range)
for col_name in names(df_init)
    df_ts_out[!, col_name] = [df_init[1, col_name]; fill(missing, length(date_range) - 1)]
end

# inject df_ts_selected values into specific row/column locations
df_ts_selected = filter(
    row -> row.date >= date_start
        && row.date <= date_end
        && row.scenario == scenario,
    df_ts
)
for row in eachrow(df_ts_selected)
    gen_id_col = string(row[id_col])  # Convert id_gen to string (column name)
    target_datetime = row.date       # Use full DateTime, not just Date
    
    # Find the row index where datetime matches exactly
    date_idx = findfirst(==(target_datetime), df_ts_out.date)
    
    # Update the value if both column and row exist
    if !isnothing(date_idx) && gen_id_col in names(df_ts_out)
        df_ts_out[date_idx, gen_id_col] = row.value
    end
end

# forward fill
forward_fill!(df_ts_out)

# for debug
println(df_ts_before_selected)
println(df_ts_selected)

# Calculate the datetime range for display
window_hours = 48
start_datetime_show = target_datetime - Hour(window_hours)
end_datetime_show = target_datetime + Hour(window_hours)
date_filter_show = (df_ts_out.date .>= start_datetime_show) .& (df_ts_out.date .<= end_datetime_show)
show(df_ts_out[date_filter_show, columns_to_check], allrows=true)
