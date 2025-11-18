using DataFrames, OrderedCollections


## Generator Output Power by Bus
# Create mapping from bus ID to component columns
# NOTE: currently, the Hydro is included as ThermalStandard
timecol = :DateTime
df_datetime = DataFrame(
    timecol => dfs_res["variable"]["ActivePowerVariable__ThermalStandard"][!, timecol]
)

df_gen_pg_list = [
    dfs_res["variable"]["ActivePowerVariable__ThermalStandard"],
    dfs_res["variable"]["ActivePowerVariable__RenewableDispatch"],
    dfs_res["parameter"]["ActivePowerTimeSeriesParameter__RenewableNonDispatch"],
]

df_gen_pg =  hcat(
    df_gen_pg_list[1],
    [select(df, Not(timecol)) for df in df_gen_pg_list[2:end]]...
)
data_cols = get_component_columns(df_gen_pg; timecol=timecol)
gen_to_bus = get_map_from_df(data["generator"], :id_gen, :id_bus)  # use id_gen
col_to_bus = get_col_to_group(data_cols, gen_to_bus)  # use id_gen + id_unit
bus_to_col = get_group_to_col(col_to_bus)  # map bus to columns

# Sum columns for each bus
df_bus_pg = sum_by_group(df_gen_pg, bus_to_col)
df_bus_pg = hcat(df_datetime, df_bus_pg)
dfs_res["post"] = Dict{String, Any}()
dfs_res["post"]["bus_pg"] = df_bus_pg

## Generator Primary Frequency Response by Bus
df_gen_uc = dfs_res["variable"]["OnVariable__ThermalStandard"]
df_gen_pg_thermal = dfs_res["variable"]["ActivePowerVariable__ThermalStandard"]

gen_to_pmax = Dict(row.id_gen => row.pmax for row in eachrow(data["generator"]))
gen_to_pfrmax = Dict(row.id_gen => row.pfrmax for row in eachrow(data["generator"]))

gen_to_unit = OrderedDict{Int64, Vector{Int64}}()
for col in get_component_columns(df_gen_pg_thermal; timecol=timecol)
    parts = split(col, "_")
    id_gen = parse(Int, parts[1])
    id_unit = parse(Int, parts[2])
    
    if !haskey(gen_to_unit, id_gen)
        gen_to_unit[id_gen] = Int64[]
    end
    push!(gen_to_unit[id_gen], id_unit)
end

# Update data["generator"] with extended version
data["generator_extended"] = extend_generator_data(data["generator"])
gen_unit_to_pmax = Dict(
    row.id_gen_unit => row.pmax 
    for row in eachrow(data["generator_extended"])
)
gen_unit_to_pfrmax = Dict(
    row.id_gen_unit => row.pfrmax 
    for row in eachrow(data["generator_extended"])
)

# Check for violations against pmax
thermal_cols = get_component_columns(df_gen_pg_thermal; timecol=timecol)
pmax_vector = [gen_unit_to_pmax[col] for col in thermal_cols if haskey(gen_unit_to_pmax, col)]
power_matrix = Matrix(df_gen_pg_thermal[!, thermal_cols])
threshold = 1e-6
violation_mask = (power_matrix .- pmax_vector') .> threshold
any(violation_mask)  # check if any violations exist

# Calculate PFR allocation
uc_matrix = Matrix(df_gen_uc[!, thermal_cols])
pfrmax_vector = [gen_unit_to_pfrmax[col] for col in thermal_cols if haskey(gen_unit_to_pfrmax, col)]
available_capacity = (pmax_vector' .* uc_matrix) .- power_matrix
pfr_limit = pfrmax_vector' .* uc_matrix
pfr_allocation = max.(min.(available_capacity, pfr_limit), 0.0)

# Create PFR allocation per bus
df_gen_pfr = hcat(df_datetime, DataFrame(pfr_allocation, thermal_cols))
df_bus_pfr = sum_by_group(df_gen_pfr, bus_to_col)
df_bus_pfr = hcat(df_datetime, df_bus_pfr)
dfs_res["post"]["bus_pfr"] = df_bus_pfr

# Area-wise Generation
area_to_bus = get_grouped_map_from_df(data["bus"], :id_area, :id_bus)
df_area_pg = sum_by_group(df_bus_pg, area_to_bus)
df_area_pg = hcat(df_datetime, df_area_pg)
dfs_res["post"]["area_pg"] = df_area_pg

# Area-wise PFR Allocation
df_area_pfr = sum_by_group(df_bus_pfr, area_to_bus)
df_area_pfr = hcat(df_datetime, df_area_pfr)
dfs_res["post"]["area_pfr"] = df_area_pfr
