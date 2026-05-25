
#==============================================================================#

@testitem "Structures" default_imports = false begin

	include("preamble.jl")

	@testset "Randomised" begin
		include("randomised.jl")
		test_randomised(round_count, benevolent_types, malevolent_types)
	end

	@testset "Show" begin
		include("show.jl")
		test_show(round_count, benevolent_types)
	end

end

#==============================================================================#
