using DataFrames, OrderedCollections
using PlotlyJS

function plot_stacked_area(
    df::DataFrame,
    id_to_name::Union{OrderedDict, Dict};
    timecol::Symbol=:DateTime,
    title::String="Stacked Area Chart",
    yaxis_title::String="Value (MW)"
)
    """
    Plot stacked area chart for aggregated data (by bus, area, etc.).
    
    # Arguments
    - `df::DataFrame`: DataFrame with time column and data columns (named by ID)
    - `id_to_name::Union{OrderedDict, Dict}`: Mapping from IDs to display names
    - `timecol::Symbol`: Name of the time column (default: :DateTime)
    - `title::String`: Plot title
    - `yaxis_title::String`: Y-axis label (default: "Value (MW)")
    
    # Returns
    - PlotlyJS plot object
    """
    # Get time column
    time_data = df[!, timecol]
    
    # Get all data columns (excluding time column)
    data_cols = [col for col in names(df) if col != String(timecol)]
    
    # Create traces for each column
    traces = GenericTrace[]
    for col in reverse(data_cols)
        col_id = parse(Int, col)
        display_name = get(id_to_name, col_id, "ID $col")  # Fallback to ID if name not found
        
        trace = scatter(
            x=time_data,
            y=df[!, col],
            name=display_name,
            mode="lines",
            stackgroup="one",
            fillcolor="tozeroy"
        )
        push!(traces, trace)
    end
    
    # Create layout
    layout = Layout(
        title=title,
        xaxis_title="Time",
        yaxis_title=yaxis_title,
        hovermode="x unified",
        legend=attr(orientation="v", yanchor="top", y=1, xanchor="left", x=1.02)
    )
    
    plot(traces, layout)
end

# Create bus ID to name mapping
bus_to_name = get_map_from_df(data["bus"], :id_bus, :name)

# Create output directory for plots
plots_dir = "examples/result/nem12/plots"
mkpath(plots_dir)

# Plot generation by bus
p_pg = plot_stacked_area(
    dfs_res["post"]["bus_pg"],
    bus_to_name;
    timecol=:DateTime,
    title="Generation by Bus",
    yaxis_title="Power (MW)",
)
savefig(p_pg, joinpath(plots_dir, "bus_pg.png"))

# Plot PFR allocation by bus
p_pfr = plot_stacked_area(
    dfs_res["post"]["bus_pfr"],
    bus_to_name;
    timecol=:DateTime,
    title="Primary Frequency Response by Bus",
    yaxis_title="Reserve Capacity (MW)",
)
savefig(p_pfr, joinpath(plots_dir, "bus_pfr.png"))

# Plot generation by area
p_area_pg = plot_stacked_area(
    dfs_res["post"]["area_pg"],
    area_to_name;
    timecol=:DateTime,
    title="Generation by Area",
    yaxis_title="Power (MW)",
)
savefig(p_area_pg, joinpath(plots_dir, "area_pg.png"))

# Plot PFR allocation by area
p_area_pfr = plot_stacked_area(
    dfs_res["post"]["area_pfr"],
    area_to_name;
    timecol=:DateTime,
    title="Primary Frequency Response by Area", 
    yaxis_title="Reserve Capacity (MW)",
)
savefig(p_area_pfr, joinpath(plots_dir, "area_pfr.png"))
