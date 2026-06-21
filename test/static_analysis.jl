
#==============================================================================#

#===============================================================================
# TODO: Introduce this file again once TestItemRunner issues are resolved.
@testitem "Static analysis" begin

	@testset "Aqua" begin
		import Aqua
		Aqua.test_all(BitPackedInstances)
	end

	@testset "JET" begin
		import JET
		JET.test_package(BitPackedInstances)
	end

end
===============================================================================#

#==============================================================================#
