names(data["generator"])

data["generator"][!, [:id_gen, :id_bus]]

gen_to_bus = Dict(
    row.id_gen => row.id_bus
    for row in eachrow(data["generator"][!, [:id_gen, :id_bus]])
)

bus_to_gen = Dict{Int64, Vector{Int64}}()
for (gen, bus) in gen_to_bus
    if !haskey(bus_to_gen, bus)
        bus_to_gen[bus] = Int64[]
    end
    push!(bus_to_gen[bus], gen)
end
