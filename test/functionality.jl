
#==============================================================================#

@testitem "Functionality" default_imports = false setup = [Preamble] begin

	@testset "Aqua" begin
		import Aqua
		Aqua.test_all(BitPackedInstances)
	end

	@testset "JET" begin
		import JET
		JET.test_package(BitPackedInstances)
	end

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
