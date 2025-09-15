using Test
using SiennaNEM
using PowerSystems



@testset "Read Data Tests" begin
    data_dir = "../data/nem12"
    data = read_system_data(data_dir)

    @test haskey(data, "bus")
    @test haskey(data, "generator")
end

@testset "Read Data Tests from Arrow" begin
    data_dir = "../data/nem12-arrow"
    data = read_system_data(data_dir)

    @test haskey(data, "bus")
    @test haskey(data, "generator")
end