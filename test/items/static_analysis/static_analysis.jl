
#==============================================================================#

@testitem "Static analysis" default_imports = false tags = [
	:static_analysis
	] setup = [
		DependencyManager
		] begin

	DependencyManager.satisfy_dependencies(@__DIR__)

	include("preamble.jl")

	@testset "Aqua" begin
		Aqua.test_all(BitPackedInstances)
	end

	@testset "JET" begin
		JET.test_package(BitPackedInstances)
	end

end

#==============================================================================#
