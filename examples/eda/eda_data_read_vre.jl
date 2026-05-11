using DataFrames
using CSV

vre_dir = joinpath(@__DIR__, "../../", "data", "out-ref4006-poe10", "csv")
rez_mesh_file_name = "rez_mesh.csv"
rooftop_mesh_file_name = "rooftop_mesh.csv"
data["rez_mesh"] = CSV.read(joinpath(vre_dir, rez_mesh_file_name), DataFrame)
data["rooftop_mesh"] = CSV.read(joinpath(vre_dir, rooftop_mesh_file_name), DataFrame)

# add bus_name to rooftop_mesh as it is currently missing
bus_to_name = SiennaNEM.get_map_from_df(data["bus"], :id_bus, :name)
add_data_col_by_id!(data["rooftop_mesh"], bus_to_name; id_col=:id_bus, data_col=:bus_name)

temerature_dir = joinpath(@__DIR__, "../..", "data/weather/temperature")
rez_temperature_file_name = "REZ_mesh_2m_temperature-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"
rez_ta_df = CSV.read(joinpath(temerature_dir, rez_temperature_file_name), DataFrame)
rooftop_temperature_file_name = "Rooftop_mesh_2m_temperature-method$(method_number)-$(date_start)_$(date_end)-era5shape$(era5_date)_$(window_name)_AEST_sched_.csv"
rooftop_ta_df = CSV.read(joinpath(temerature_dir, rooftop_temperature_file_name), DataFrame)

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
