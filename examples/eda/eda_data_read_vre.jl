using DataFrames
using CSV
using Statistics

vre_dir = joinpath(@__DIR__, "../../", "data", "out-ref4006-poe10", "csv")
rez_mesh_file_name = "rez_mesh.csv"
rooftop_mesh_file_name = "rooftop_mesh.csv"
data["rez_mesh"] = CSV.read(joinpath(vre_dir, rez_mesh_file_name), DataFrame)
data["rooftop_mesh"] = CSV.read(joinpath(vre_dir, rooftop_mesh_file_name), DataFrame)

# add bus_name and id_area to rooftop_mesh as it is currently missing
bus_to_name = SiennaNEM.get_map_from_df(data["bus"], :id_bus, :name)
add_data_col_by_id!(data["rooftop_mesh"], bus_to_name; id_col=:id_bus, data_col=:bus_name)
SiennaNEM.add_id_area_col!(data["rez_mesh"], bus_to_area)
SiennaNEM.add_id_area_col!(data["rooftop_mesh"], bus_to_area)

# add tref_summer to rooftop_mesh and rez_mesh data for later use in solar derating factor calculation
add_data_col_by_id!(data["rez_mesh"], SiennaNEM.area_to_tref_summer; data_col=:tref_summer)
add_data_col_by_id!(data["rooftop_mesh"], SiennaNEM.area_to_tref_summer; data_col=:tref_summer)

temperature_dir = joinpath(@__DIR__, "../..", "data/weather/temperature")
rez_temperature_file_name = "REZ_mesh_2m_temperature-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"
rez_ta_df = CSV.read(joinpath(temperature_dir, rez_temperature_file_name), DataFrame)
rooftop_temperature_file_name = "Rooftop_mesh_2m_temperature-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"
rooftop_ta_df = CSV.read(joinpath(temperature_dir, rooftop_temperature_file_name), DataFrame)

count(ismissing, Matrix(rez_ta_df))
count(ismissing, Matrix(rooftop_ta_df))

# remove rooftop with missing temperature data
id_rooftop_mesh_with_missing =
    unique(rooftop_ta_df.id_rooftop_mesh[ismissing.(rooftop_ta_df.value)])
filter!(row -> !(row.id_rooftop_mesh in id_rooftop_mesh_with_missing), rooftop_ta_df)
filter!(row -> !(row.id_rooftop_mesh in id_rooftop_mesh_with_missing), data["rooftop_mesh"])

# bus mesh counts
rez_counts = combine(groupby(data["rez_mesh"], :id_bus), nrow => :n_rez_mesh)
rooftop_counts = combine(groupby(data["rooftop_mesh"], :id_bus), nrow => :n_rooftop_mesh)
bus_mesh_counts = outerjoin(rez_counts, rooftop_counts; on=:id_bus)
add_data_col_by_id!(bus_mesh_counts, bus_to_name; id_col=:id_bus, data_col=:bus_name)
bus_mesh_counts
# 12×3 DataFrame
#  Row │ id_bus  n_rez_mesh  n_rooftop_mesh 
#      │ Int64   Int64       Int64          
# ─────┼────────────────────────────────────
#    1 │      1         239              15
#    2 │      2         119              10
#    3 │      3         113              13
#    4 │      4          87              22
#    5 │      5          67              20
#    6 │      6          35               9
#    7 │      7          15              14
#    8 │      8         131              18
#    9 │      9         143              20
#   10 │     10          71              16
#   11 │     11         180              19
#   12 │     12          53              20

## Wind
rez_windcf_sched = get_wind_thermal_correction_factor(
    rez_ta_df, data["rez_mesh"];
    gen_id_col=:id_rez_mesh,
    altitude_col=nothing,
)
# CSV.write(joinpath(outdir, "Generator_cf_rezwind-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"), rez_windcf_sched)
rez_windcf_sched

# Aggregate by bus, unweighted mean across mesh points
rez_windcf_bus = leftjoin(
    rez_windcf_sched,
    select(data["rez_mesh"], :id_rez_mesh, :id_bus, :bus_name, :id_rez, :rez_name);
    on = :id_rez_mesh
)
rez_windcf_bus_mean = combine(
    groupby(rez_windcf_bus, [:scenario, :date, :id_bus, :bus_name, :id_rez, :rez_name]),
    :value => mean => :cf_mean,
    nrow => :n_mesh
)
CSV.write(joinpath(outdir, "Generator_cf_aggregate_wind-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"), rez_windcf_bus_mean)

## LargePV
rez_pvmodcf_largepv_sched = get_pv_module_temperature_correction_factor_nonconservative(
    rez_ta_df, data["rez_mesh"];
    gen_id_col=:id_rez_mesh,
    U0=25.0, U1=6.84,
)
# CSV.write(joinpath(outdir, "Generator_cf_rezlargepv_pvmod-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"), rez_pvmodcf_largepv_sched)
rez_pvmodcf_largepv_sched

# Aggregate by bus, unweighted mean across mesh points
rez_pvmodcf_largepv_bus = leftjoin(
    rez_pvmodcf_largepv_sched,
    select(data["rez_mesh"], :id_rez_mesh, :id_bus, :bus_name, :id_rez, :rez_name);
    on = :id_rez_mesh
)
rez_pvmodcf_largepv_bus_mean = combine(
    groupby(rez_pvmodcf_largepv_bus, [:scenario, :date, :id_bus, :bus_name, :id_rez, :rez_name]),
    :value => mean => :cf_mean,
    nrow => :n_mesh
)
CSV.write(joinpath(outdir, "Generator_cf_aggregate_largepv_pvmod-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"), rez_pvmodcf_largepv_bus_mean)

## RooftopPV
rooftop_pvmodcf_roofpv_sched = get_pv_module_temperature_correction_factor_nonconservative(
    rooftop_ta_df, data["rooftop_mesh"];
    gen_id_col=:id_rooftop_mesh,
    U0=25.0, U1=6.84,
)
# CSV.write(joinpath(outdir, "Generator_cf_meshroofpv_pvmod-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"), rooftop_pvmodcf_roofpv_sched)
rooftop_pvmodcf_roofpv_sched

# Aggregate by bus, unweighted mean across mesh points
rooftop_pvmodcf_roofpv_bus = leftjoin(
    rooftop_pvmodcf_roofpv_sched,
    select(data["rooftop_mesh"], :id_rooftop_mesh, :id_bus, :bus_name);
    on = :id_rooftop_mesh
)
rooftop_pvmodcf_roofpv_bus_mean = combine(
    groupby(rooftop_pvmodcf_roofpv_bus, [:scenario, :date, :id_bus, :bus_name]),
    :value => mean => :cf_mean,
    nrow => :n_mesh
)
CSV.write(joinpath(outdir, "Generator_cf_aggregate_roofpv_pvmod-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"), rooftop_pvmodcf_roofpv_bus_mean)
