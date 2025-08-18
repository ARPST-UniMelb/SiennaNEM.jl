using Test
using SiennaNEM

@testset "Read Data Tests" begin
    data_dir = "data/nem12"
    data = read_data_csv(data_dir)

    @test haskey(data, "bus")
    @test haskey(data, "generator")
end
