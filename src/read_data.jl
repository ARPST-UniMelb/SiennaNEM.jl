function read_data_csv(data_dir)
    bus_path = joinpath(data_dir, "Bus.csv")
    generator_path = joinpath(data_dir, "Generator.csv")
    line_path = joinpath(data_dir, "Line.csv")
    demand_path = joinpath(data_dir, "Demand.csv")
    storage_path = joinpath(data_dir, "_orig_ESS.csv")

    df_data = Dict{String, Any}()
    df_data["bus"] = CSV.read(bus_path, DataFrame)
    df_data["generator"] = CSV.read(generator_path, DataFrame)
    df_data["line"] = CSV.read(line_path, DataFrame)
    df_data["demand"] = CSV.read(demand_path, DataFrame)
    df_data["storage"] = CSV.read(storage_path, DataFrame)
    return df_data
end
