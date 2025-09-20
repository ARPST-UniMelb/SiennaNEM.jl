using SiennaNEM
using DataFrames
using CSV
using Dates

"""
    forward_fill!(df; col_names)

Performs forward fill (last observation carried forward) in a DataFrame.

# Arguments
- `df`: DataFrame to modify in-place
- `col_names`: Collection of column names (Symbols) to forward fill

# Assumptions
- First row values are never missing (pre-allocated/known values)
- Specified columns exist in the DataFrame

# Example
```julia
numeric_cols = [:1_1, :1_2, :2_1, :3_1]
forward_fill!(df; col_names=numeric_cols)
```
"""
function forward_fill!(df; col_names)
    for col_name in col_names
        col = df[!, col_name]
        
        # Inline the forward fill logic for maximum performance
        @inbounds begin
            last_valid = col[1]  # First value is never missing (assumption)
            for i in 2:length(col)
                if ismissing(col[i])
                    col[i] = last_valid
                else
                    last_valid = col[i]
                end
            end
        end
    end
end

"""
    create_timeseries_df(df_static, df_ts, id_col, col_ref, scenario, date_start, date_end; interval=Dates.Hour(1))

Create a time series DataFrame with forward-filled values by combining static and time series data.

# Arguments
- `df_static`: Static data DataFrame containing baseline values
- `df_ts`: Time series data DataFrame with columns: date, scenario, id_col, value
- `id_col`: Column name for ID (String, e.g., "id_gen", "id_storage")
- `col_ref`: Column name for static reference (String, e.g., "pmax", "n", "emax")
- `scenario`: Scenario number (Integer) to filter time series data
- `date_start`: Start date (DateTime) for the output time series
- `date_end`: End date (DateTime) for the output time series
- `interval`: Time interval for the output series (default: Dates.Hour(1))

# Returns
- `df_ts_out`: Output time series DataFrame with date column and forward-filled values
- `df_ts_before_selected`: DataFrame with latest values before date_start (for debugging)
- `df_ts_selected`: DataFrame with values in the selected period (for debugging)

# Process
1. Initialize with static baseline values from df_static
2. Update with latest available values before date_start (if any)
3. Create hourly time series from date_start to date_end
4. Inject specific time series values from df_ts where available
5. Forward-fill missing values to ensure complete coverage

# Example
```julia
df_out, df_before, df_selected = create_timeseries_df(
    df_generator, df_generator_pmax_ts, "id_gen", "pmax", 1,
    DateTime(2044, 6, 28), DateTime(2044, 7, 2)
)
```
"""
function create_timeseries_df(
    df_static, df_ts, id_col, col_ref, scenario, date_start, date_end;
    interval=Dates.Hour(1),
)
    # NOTE: if needed, this can be further optimized by pre-allocate with values
    
    # Create initial data
    id_col_val = string.(df_static[!, id_col])
    col_ref_val = df_static[!, col_ref]
    df_init = DataFrame(Dict(zip(id_col_val, col_ref_val)))
    col_names = names(df_init)

    # Get data before selected period
    df_ts_before_selected = filter(
        row -> row.date < date_start && row.scenario == scenario,
        df_ts
    )

    # Update df_init with latest values before selected period
    if nrow(df_ts_before_selected) > 0
        # Get latest values before date
        df_ts_before_selected = combine(groupby(df_ts_before_selected, id_col)) do group
            subset(group, :date => x -> x .== maximum(x))
        end

        # Update init using latest values
        ids_update = string.(df_ts_before_selected[!, id_col])
        gen_values_update = df_ts_before_selected.value
        df_init[1, ids_update] .= gen_values_update
    end

    # Pre-allocate output DataFrame
    date_range = collect(date_start:interval:date_end)
    df_ts_out = DataFrame(date=date_range)
    for col_name in col_names
        df_ts_out[!, col_name] = [
            df_init[1, col_name]; fill(missing, length(date_range) - 1)
        ]
    end

    # Get data in selected period and inject values
    df_ts_selected = filter(
        row -> row.date >= date_start
            && row.date <= date_end
            && row.scenario == scenario,
        df_ts
    )
    
    for row in eachrow(df_ts_selected)
        gen_id_col = string(row[id_col])  # Convert id to string (column name)
        
        # Find the row index where datetime matches exactly
        date_idx = findfirst(==(row.date), df_ts_out.date)
        
        # Update the value if both column and row exist
        if !isnothing(date_idx) && gen_id_col in col_names
            df_ts_out[date_idx, gen_id_col] = row.value
        end
    end

    # Forward fill missing values
    forward_fill!(df_ts_out; col_names=col_names)

    return df_ts_out, df_ts_before_selected, df_ts_selected
end

# Load data
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
# Sienna doesn't support change of emax and lmax, we need to add that as extra constraints straight to JuMP data
# Sienna also doesn't support change of n, that is number of available unit
# When we add constraints to JuMP model, check first is the timeseries data changes or not

# ================================
# DEBUG SECTION
# ================================

# Configuration for debugging n
# df_static = df_generator
# id_col = "id_gen"
# col_ref = "n"
# df_ts = df_generator_n_ts
# target_datetime = DateTime("2024-02-01T00:00:00")
# columns_to_check = ["date", "1", "84", "69"]
# date_start = DateTime(2024, 1, 1)
# date_end = DateTime(2025, 1, 1)

# Configuration for debugging pmax
df_static = df_generator
id_col = "id_gen"
col_ref = "pmax"
df_ts = df_generator_pmax_ts
target_datetime = DateTime("2044-06-30T00:00:00")
columns_to_check = ["date", "78", "79"]
date_start = DateTime(2044, 6, 28)
date_end = DateTime(2044, 7, 2)

# Scenario
scenario = 1

# Create time series
df_ts_out, df_ts_before_selected, df_ts_selected = create_timeseries_df(
    df_static, df_ts, id_col, static_col_ref, scenario, date_start, date_end
)

# Debug output
println("Before selected period:")
println(df_ts_before_selected)
println("\nSelected period:")
println(df_ts_selected)

# Calculate the datetime range for display
window_hours = 48
start_datetime_show = target_datetime - Hour(window_hours)
end_datetime_show = target_datetime + Hour(window_hours)
date_filter_show = (df_ts_out.date .>= start_datetime_show) .& (df_ts_out.date .<= end_datetime_show)

println("\nTime series output (around target datetime):")
show(df_ts_out[date_filter_show, columns_to_check], allrows=true)