using Dates
using DataFrames
using Statistics
using PlotlyJS
import PlotlyJS: scatter, Layout, Plot, attr

# --- choose one bus ---
id_bus_sel = 8

# --- prep: parse datetime ---
df_bus = filter(:id_bus => ==(id_bus_sel), rez_windcf_bus)

# robust DateTime parsing (your :date looks like String)
df_bus[!, :datetime] = DateTime.(df_bus[!, :date], dateformat"yyyy-mm-dd HH:MM:SS")
sort!(df_bus, [:id_rez_mesh, :datetime])

# optional: filter date range
dt_start = DateTime("2038-01-23 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
dt_end   = DateTime("2038-01-25 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
df_bus = filter(:datetime => d -> dt_start <= d <= dt_end, df_bus)

# --- compute mean per timestamp (across meshes) ---
df_mean = combine(groupby(df_bus, [:scenario, :datetime]), :value => mean => :cf_mean)
sort!(df_mean, :datetime)

# bus label (handles empty + missing)
bus_name = let
    if nrow(df_bus) == 0
        "bus $(id_bus_sel)"
    else
        nm = collect(skipmissing(df_bus.bus_name))
        isempty(nm) ? "bus $(id_bus_sel)" : first(nm)
    end
end

# --- build traces ---
mesh_color = "rgba(30,144,255,0.18)"   # dodgerblue with transparency
mean_color = "rgba(0,0,0,1.0)"

mesh_ids = unique(df_bus.id_rez_mesh)
mesh_traces = PlotlyJS.GenericTrace[]

for mid in mesh_ids
    sub = view(df_bus, df_bus.id_rez_mesh .== mid, :)
    push!(mesh_traces,
        scatter(
            x = sub.datetime,
            y = sub.value,
            mode = "lines",
            name = "mesh $(mid)",
            showlegend = false,
            line = attr(color = mesh_color, width = 1),
            hovertemplate = "mesh %{text}<br>%{x}<br>cf=%{y:.3f}<extra></extra>",
            text = fill(string(mid), nrow(sub)),
        )
    )
end

mean_trace = scatter(
    x = df_mean.datetime,
    y = df_mean.cf_mean,
    mode = "lines",
    name = "mean",
    line = attr(color = mean_color, width = 3),
    hovertemplate = "mean<br>%{x}<br>cf=%{y:.3f}<extra></extra>",
)

layout = Layout(
    title = "REZ wind CF — meshes + mean (bus $(id_bus_sel): $(bus_name))",
    xaxis = attr(title = "Date"),
    yaxis = attr(title = "CF (p.u.)"),
    width = 1000,
    height = 450,
    legend = attr(x = 1.02, y = 1.0),
    margin = attr(l = 70, r = 40, t = 70, b = 60),
    annotations = [
        attr(
            x = 0.01, y = 0.99, xref = "paper", yref = "paper",
            xanchor = "left", yanchor = "top",
            text = "bus $(id_bus_sel): $(bus_name)",
            showarrow = false,
            font = attr(size = 12, color = "black"),
            bgcolor = "rgba(255,255,255,0.7)",
            bordercolor = "rgba(0,0,0,0.2)",
            borderwidth = 1,
        )
    ],
)

plt = Plot([mesh_traces... , mean_trace], layout)
plt

# For different colors between REZ
using Dates
using DataFrames
using Statistics
using PlotlyJS
import PlotlyJS: scatter, Layout, Plot, attr

# ...existing code...

# --- compute mean per timestamp ---
# overall mean (across all meshes at the bus)
df_mean = combine(groupby(df_bus, [:scenario, :datetime]), :value => mean => :cf_mean)
sort!(df_mean, :datetime)

# NEW: mean per REZ (across meshes in that REZ) at the bus
df_mean_rez = combine(
    groupby(df_bus, [:scenario, :datetime, :id_rez, :rez_name]),
    :value => mean => :cf_mean_rez
)
sort!(df_mean_rez, [:id_rez, :datetime])

# --- colors: one base RGB per REZ, then use alpha for mesh vs mean ---
# (repeatable palette; extend if you have >10 REZ at a bus)
palette_rgb = [
    (31, 119, 180),  # blue
    (255, 127, 14),  # orange
    (44, 160, 44),   # green
    (214, 39, 40),   # red
    (148, 103, 189), # purple
    (140, 86, 75),   # brown
    (227, 119, 194), # pink
    (127, 127, 127), # gray
    (188, 189, 34),  # olive
    (23, 190, 207),  # cyan
]
rgba(rgb::NTuple{3,Int}, a::Real) = "rgba($(rgb[1]),$(rgb[2]),$(rgb[3]),$(Float64(a)))"

rez_keys = unique(select(df_bus, :id_rez, :rez_name))
sort!(rez_keys, :id_rez)

rez_to_rgb = Dict{Int, NTuple{3,Int}}()
for (i, r) in enumerate(eachrow(rez_keys))
    rez_to_rgb[r.id_rez] = palette_rgb[mod1(i, length(palette_rgb))]
end

mesh_alpha = 0.18
mean_alpha = 1.0

# --- build traces ---
mesh_traces = PlotlyJS.GenericTrace[]

# NEW: group meshes by REZ so they get the same shade
for r in eachrow(rez_keys)
    id_rez = r.id_rez
    rez_name = r.rez_name

    base_rgb = rez_to_rgb[id_rez]
    mesh_color = rgba(base_rgb, mesh_alpha)

    # plot each mesh line (transparent) for this REZ
    mesh_ids_rez = unique(df_bus.id_rez_mesh[df_bus.id_rez .== id_rez])
    for mid in mesh_ids_rez
        sub = view(df_bus, (df_bus.id_rez_mesh .== mid) .& (df_bus.id_rez .== id_rez), :)
        push!(mesh_traces,
            scatter(
                x = sub.datetime,
                y = sub.value,
                mode = "lines",
                name = "REZ $(id_rez): $(rez_name)", # legend handled by mean line
                showlegend = false,
                line = attr(color = mesh_color, width = 1),
                hovertemplate = "REZ: %{customdata[1]}<br>mesh %{customdata[2]}<br>%{x}<br>cf=%{y:.3f}<extra></extra>",
                customdata = hcat(fill(string(rez_name), nrow(sub)), fill(string(mid), nrow(sub))),
            )
        )
    end
end

# NEW: mean line per REZ (opaque, shown in legend)
mean_rez_traces = PlotlyJS.GenericTrace[]
for r in eachrow(rez_keys)
    id_rez = r.id_rez
    rez_name = r.rez_name
    base_rgb = rez_to_rgb[id_rez]
    mean_color = rgba(base_rgb, mean_alpha)

    subm = view(df_mean_rez, df_mean_rez.id_rez .== id_rez, :)
    push!(mean_rez_traces,
        scatter(
            x = subm.datetime,
            y = subm.cf_mean_rez,
            mode = "lines",
            name = "REZ $(id_rez): $(rez_name) mean",
            line = attr(color = mean_color, width = 3),
            hovertemplate = "REZ mean<br>REZ: $(rez_name)<br>%{x}<br>cf=%{y:.3f}<extra></extra>",
        )
    )
end

# OPTIONAL: overall bus mean (black)
overall_mean_trace = scatter(
    x = df_mean.datetime,
    y = df_mean.cf_mean,
    mode = "lines",
    name = "bus mean",
    line = attr(color = "rgba(0,0,0,1.0)", width = 4, dash = "dash"),
    hovertemplate = "bus mean<br>%{x}<br>cf=%{y:.3f}<extra></extra>",
)

layout = Layout(
    title = "REZ wind CF — meshes + REZ means (bus $(id_bus_sel): $(bus_name))",
    xaxis = attr(title = "Date"),
    yaxis = attr(title = "CF (p.u.)"),
    width = 1100,
    height = 500,
    legend = attr(x = 1.02, y = 1.0),
    margin = attr(l = 70, r = 40, t = 70, b = 60),
    annotations = [
        attr(
            x = 0.01, y = 0.99, xref = "paper", yref = "paper",
            xanchor = "left", yanchor = "bottom",
            text = "bus $(id_bus_sel): $(bus_name)",
            showarrow = false,
            font = attr(size = 12, color = "black"),
            bgcolor = "rgba(255,255,255,0.7)",
            bordercolor = "rgba(0,0,0,0.2)",
            borderwidth = 1,
        )
    ],
)

plt = Plot([mesh_traces...; mean_rez_traces...; overall_mean_trace], layout)
plt
