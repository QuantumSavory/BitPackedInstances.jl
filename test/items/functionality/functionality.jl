
#==============================================================================#

@testitem "Functionality" default_imports = false tags = [
	:functionality
	] setup = [
		DependencyManager
		] begin

	DependencyManager.satisfy_dependencies(@__DIR__)

	include("preamble.jl")

	@testset "Randomised" begin
		test_randomised(round_count, benevolent_types, malevolent_types)
	end

	@testset "Progression" begin
		test_progression(generated_enums)
	end

	@testset "Show" begin
		test_show(round_count, benevolent_types)
	end

end

#==============================================================================#
