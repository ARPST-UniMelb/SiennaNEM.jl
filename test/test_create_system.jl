using Test
using SiennaNEM

const PSY = PowerSystems

@testset "Create System Tests" begin
    data_dir = "../data/nem12"
    data = read_system_data(data_dir)
    create_system!(data)

    @test haskey(data, "sys")
    @test typeof(data["sys"]) == PSY.System
end

@testset "Create System Tests from Arrow" begin
    data_dir = "../data/nem12-arrow"
    data = read_system_data(data_dir)
    create_system!(data)

    @test haskey(data, "sys")
    @test typeof(data["sys"]) == PSY.System
end
