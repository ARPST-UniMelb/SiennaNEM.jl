using DataFrames


## Generator Output Power by Bus
# Create mapping from bus ID to component columns
# NOTE: currently, the Hydro is included as ThermalStandard
timecol = :DateTime
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
gen_to_bus = get_gen_to_bus(data["generator"])  # use gen_id
col_to_bus = get_col_to_bus(data_cols, gen_to_bus)  # use gen_id + sub_id
bus_to_col = get_bus_to_col(col_to_bus)  # map bus to columns

# Sum columns for each bus
df_res_bus_pg = sum_by_bus(df_gen_pg, bus_to_col)
df_res_bus_pg = hcat(DataFrame(timecol => df_gen_pg[!, timecol]), df_res_bus_pg)
dfs_res["post"] = Dict{String, Any}()
dfs_res["post"]["bus_pg"] = df_res_bus_pg

## Generator Primary Frequency Response by Bus
df_gen_uc = dfs_res["variable"]["OnVariable__ThermalStandard"]
