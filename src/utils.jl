using DataFrames, Dates, TimeSeries, OrderedCollections

function add_day!(df)
    transform!(df, :date => ByRow(x -> Date(x)) => :day)
end

function date_as_datetime!(df)
    if !(eltype(df.date) <: DateTime)
        df.date = DateTime.(df.date, DateFormat("yyyy-mm-dd HH:MM:SS"))
    end
end

function preprocess_date!(df)
    date_as_datetime!(df)
    add_day!(df)
end

function groupbyd(df::Union{DataFrame, SubDataFrame}, col::Symbol)
    return Dict(g[!, col][1] => g for g in groupby(df, col))
end

function groupby_scenario_at_init_day(df::DataFrame)
    init_time = minimum(df[!, :date])
    init_day = Date(init_time)
    return groupby_scenario_at_day(df, init_day)
end

function groupby_scenario_at_day(df::DataFrame, day::Date)
    df_init_day = subset(df, :day => ByRow(==(day)))
    return groupbyd(df_init_day, :scenario)
end

function groupby_scenario(df::DataFrame)
    return groupbyd(df, :scenario)
end

function show_parameter(df_parameter)
    # NOTE: I don't know why it require println()
    show(df_parameter, allrows=true, allcols=true)
    println()
end

function sort_res_cols(df::DataFrame)
    """
    Sort columns while moving DateTime to first position if present.
    Handles both nested (M_N) and non-nested column names.
    """
    if "DateTime" in names(df)
        other_cols = filter(!=("DateTime"), names(df))
        sorted_cols = sort(other_cols; by = name -> parse.(Int, split(name, "_")))
        return select(df, ["DateTime"; sorted_cols])
    else
        sorted_cols = sort(names(df); by = name -> parse.(Int, split(name, "_")))
        return select(df, sorted_cols)
    end
end

function diff_df(df1::DataFrame, df2::DataFrame; timecol::Symbol = :DateTime)
    numeric_names = names(df1, Not(timecol))
    numeric_diff = DataFrame(
        Matrix(select(df1, Not(timecol))) .- Matrix(select(df2, Not(timecol))),
        numeric_names
    )
    return hcat(DataFrame(timecol => df1[!, timecol]), numeric_diff)
end

function get_map_from_df(df::DataFrame, col1::Symbol, col2::Symbol)
    """
    Create a mapping from values in col1 to values in col2.
    
    # Arguments
    - `df::DataFrame`: DataFrame containing the columns
    - `col1::Symbol`: Column name to use as keys
    - `col2::Symbol`: Column name to use as values
    
    # Returns
    - `OrderedDict`: Dictionary mapping col1 values to col2 values
    
    # Example
    ```julia
    bus_to_area = get_map_from_df(data["bus"], :id_bus, :id_area)
    gen_to_bus = get_map_from_df(data["generator"], :id_gen, :id_bus)
    ```
    """
    return OrderedDict(
        row[col1] => row[col2]
        for row in eachrow(df[!, [col1, col2]])
    )
end

function get_inverse_map(forward_map::OrderedDict{K, V}) where {K, V}
    """
    Create an inverse mapping that groups keys by their values.
    
    # Arguments
    - `forward_map::OrderedDict{K, V}`: Dictionary mapping keys to values
    
    # Returns
    - `OrderedDict{V, Vector{K}}`: Dictionary mapping values to vectors of keys
    
    # Example
    ```julia
    gen_to_bus = get_gen_to_bus(data["generator"])
    bus_to_gen = get_inverse_map(gen_to_bus)
    ```
    """
    inverse_map = OrderedDict{V, Vector{K}}()
    for (key, val) in forward_map
        if !haskey(inverse_map, val)
            inverse_map[val] = K[]
        end
        push!(inverse_map[val], key)
    end
    return inverse_map
end

function get_gen_to_bus(df_generator::DataFrame)
    """
    Create a mapping from generator ID to bus ID.
    
    # Arguments
    - `df_generator::DataFrame`: DataFrame containing "generator" data
    
    # Returns
    - `OrderedDict{Int64, Int64}`: Dictionary mapping generator IDs to bus IDs
    """
    return get_map_from_df(df_generator, :id_gen, :id_bus)
end

function get_bus_to_gen(gen_to_bus::OrderedDict{Int64, Int64})
    """
    Create a mapping from bus ID to generator IDs.
    
    # Arguments
    - `gen_to_bus::OrderedDict`: Dictionary mapping generator IDs to bus IDs
    
    # Returns
    - `OrderedDict{Int64, Vector{Int64}}`: Dictionary mapping bus IDs to vectors of generator IDs
    """
    return get_inverse_map(gen_to_bus)
end

function get_col_to_bus(data_cols::Vector{String}, com_to_bus::OrderedDict{Int64, Int64})
    """
    Create a mapping from column names to bus IDs.
    
    # Arguments
    - `data_cols::Vector{String}`: Vector of column names (e.g., ["1_2", "1_3", "2_1"])
    - `com_to_bus::OrderedDict{Int64, Int64}`: Dictionary mapping component IDs to bus IDs
    
    # Returns
    - `OrderedDict{String, Int64}`: Dictionary mapping column names to bus IDs
    """
    col_to_bus = OrderedDict{String, Int64}()
    for col in data_cols
        com_id = parse(Int, split(col, "_")[1])  # Extract com_id from "com_id_sub_id"
        if haskey(com_to_bus, com_id)
            col_to_bus[col] = com_to_bus[com_id]
        end
    end
    return col_to_bus
end

function get_bus_to_col(col_to_bus::OrderedDict{String, Int64})
    """
    Create a mapping from bus IDs to column names.
    
    # Arguments
    - `col_to_bus::OrderedDict{String, Int64}`: Dictionary mapping column names to bus IDs
    
    # Returns
    - `OrderedDict{Int64, Vector{String}}`: Dictionary mapping bus IDs to vectors of column names
    """
    return get_inverse_map(col_to_bus)
end

function get_component_columns(df::DataFrame; timecol::Symbol = :DateTime)
    return filter(x -> x != String(timecol), names(df))
end

function sum_by_bus(df::DataFrame, com_to_bus::Dict{Int64, Int64}; timecol::Symbol = :DateTime)
    """
    Aggregate component columns by bus ID. This uses `sum_by_bus` internally.
    
    # Arguments
    - `df::DataFrame`: DataFrame with columns named as "com_id_sub_id" (e.g., "1_2")
    - `com_to_bus::Dict{Int64, Int64}`: Dictionary mapping component IDs to bus IDs
    - `timecol::Symbol`: Name of the time column to preserve (default: :DateTime)
    
    # Returns
    - `DataFrame`: DataFrame with columns aggregated by bus ID, with time column as first column if present
    
    # Example
    ```julia
    gen2bus = get_gen_to_bus(data)
    df_by_bus = sum_by_bus(df_gen_power, gen2bus)
    ```
    """
    # Get component columns (exclude time column)
    data_cols = get_component_columns(df; timecol=timecol)
    
    # Create mapping from bus ID to component columns
    col_to_bus = get_col_to_bus(data_cols, com_to_bus)
    bus_to_col = get_bus_to_col(col_to_bus)

    # Sum columns for each bus
    df_result = sum_by_bus(df, bus_to_col)
    
    # Combine with time column if it exists (as first column)
    if hasproperty(df, timecol)
        df_result = hcat(DataFrame(timecol => df[!, timecol]), df_result)
    end

    return df_result
end

function sum_by_bus(df::DataFrame, bus_to_col::OrderedDict{Int64, Vector{String}})
    """
    Sum DataFrame columns grouped by bus ID.
    
    # Arguments
    - `df::DataFrame`: DataFrame with component columns
    - `bus_to_col::OrderedDict{Int64, Vector{String}}`: Dictionary mapping bus IDs to column names
    
    # Returns
    - `DataFrame`: DataFrame with summed columns per bus (columns named by bus ID)
    """
    df_result = DataFrame()
    for bus in sort(collect(keys(bus_to_col)))
        cols = bus_to_col[bus]
        # Filter to only include columns that exist in df
        existing_cols = filter(col -> hasproperty(df, col), cols)
        if !isempty(existing_cols)
            df_result[!, string(bus)] = sum(df[!, col] for col in existing_cols)
        end
    end
    return df_result
end
