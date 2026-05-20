using BitPackedInstances
using Test
using Aqua
using JET

@testset "BitPackedInstances.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(BitPackedInstances)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(BitPackedInstances; target_defined_modules = true)
    end
    # Write your tests here.
end
