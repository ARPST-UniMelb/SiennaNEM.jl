using DataFrames, OrderedCollections
using PlotlyJS

function plot_bus_data(
    df::DataFrame,
    bus_to_name::OrderedDict{Int64, String};
    timecol::Symbol=:DateTime,
    title::String="Data by Bus",
    yaxis_title::String="Value (MW)"
)
    """
    Plot stacked area chart for bus-level data.
    
    # Arguments
    - `df::DataFrame`: DataFrame with time column and bus columns (named by bus ID)
    - `bus_to_name::OrderedDict{Int64, String}`: Mapping from bus IDs to bus names
    - `timecol::Symbol`: Name of the time column (default: :DateTime)
    - `title::String`: Plot title (default: "Data by Bus")
    - `yaxis_title::String`: Y-axis label (default: "Value (MW)")
    
    # Returns
    - PlotlyJS plot object
    """
    # Get time column
    time_data = df[!, timecol]
    
    # Get all bus columns (excluding time column)
    bus_cols = [col for col in names(df) if col != String(timecol)]
    
    # Create traces for each bus
    traces = GenericTrace[]
    for bus_col in reverse(bus_cols)
        bus_id = parse(Int, bus_col)
        bus_name = get(bus_to_name, bus_id, "Bus $bus_col")  # Fallback to ID if name not found
        
        trace = scatter(
            x=time_data,
            y=df[!, bus_col],
            name=bus_name,
            mode="lines",
            stackgroup="one",  # This creates the stacked effect
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
    
    # Create and display plot
    plot(traces, layout)
end

# Create bus ID to name mapping
bus_to_name = get_map_from_df(data["bus"], :id_bus, :name)

# Create output directory for plots
plots_dir = "examples/result/nem12/plots"
mkpath(plots_dir)

# Plot generation by bus
p_pg = plot_bus_data(
    dfs_res["post"]["bus_pg"],
    bus_to_name;
    timecol=:DateTime,
    title="Generation by Bus",
    yaxis_title="Power (MW)"
)
savefig(p_pg, joinpath(plots_dir, "bus_pg.png"))

# Plot PFR allocation by bus
p_pfr = plot_bus_data(
    dfs_res["post"]["bus_pfr"],
    bus_to_name;
    timecol=:DateTime,
    title="Primary Frequency Response by Bus",
    yaxis_title="Reserve Capacity (MW)"
)
savefig(p_pfr, joinpath(plots_dir, "bus_pfr.png"))
