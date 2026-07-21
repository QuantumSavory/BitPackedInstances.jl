
#==============================================================================#

JET_flag = ARGS == ["jet"]

if JET_flag
	@info "Running JET tests in their dedicated test environment."
	using Pkg
	Pkg.activate(joinpath(@__DIR__, "projects", "jet"))
	Pkg.instantiate()
else
	@info "Skipping JET tests -- pass `test_args=[\"jet\"]` to Pkg.test to enable them."
end

using TestItemRunner

testfilter = ti -> JET_flag ? (:jet in ti.tags) : !(:jet in ti.tags)

@run_package_tests filter=testfilter

#==============================================================================#
