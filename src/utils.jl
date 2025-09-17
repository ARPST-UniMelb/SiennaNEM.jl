using DataFrames, Dates, TimeSeries

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

function sort_res_cols(df)
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
