using PlotlyJS

function plot_bus_power(df::DataFrame; timecol::Symbol=:DateTime)
    # Get time column
    time_data = df[!, timecol]
    
    # Get all bus columns (excluding time column)
    bus_cols = [col for col in names(df) if col != String(timecol)]
    
    # Create traces for each bus
    traces = GenericTrace[]
    for bus_col in reverse(bus_cols)
        trace = scatter(
            x=time_data,
            y=df[!, bus_col],
            name="Bus $bus_col",
            mode="lines",
            stackgroup="one",  # This creates the stacked effect
            fillcolor="tozeroy"
        )
        push!(traces, trace)
    end
    
    # Create layout
    layout = Layout(
        title="Generation by Bus",
        xaxis_title="Time",
        yaxis_title="Power (MW)",
        hovermode="x unified",
        legend=attr(orientation="v", yanchor="top", y=1, xanchor="left", x=1.02)
    )
    
    # Create and display plot
    plot(traces, layout)
end

# Plot the results
plots_dir = "examples/result/nem12/plots"
mkpath(plots_dir)
p = plot_bus_power(dfs_res["post"]["bus_pg"]; timecol=:DateTime)
savefig(p, joinpath(plots_dir, "bus_pg.png"))
