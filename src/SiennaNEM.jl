module SiennaNEM

using PowerSystems
using DataFrames
using CSV

const PSY = PowerSystems
const DF = DataFrames

include("const.jl")
include("read_data.jl")
include("create_system.jl")

# Environment variables for configuration
const ENV_HYDRORES_AS_THERMAL = true
const ENV_HYDROPUMP_AS_BATTERY = true

# Exported functions and constants
export read_data_csv, create_system!
export type_to_primemover, type_to_datatype, type_to_fuel
export get_flat_generators, get_generator_units, count_all_generators

end