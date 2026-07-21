
#==============================================================================#

const JET_PROJECT = normpath(joinpath(@__DIR__, "projects", "jet"))
const test_args = isempty(ARGS) ? ["general"] : ARGS
const JET_flag = length(test_args) == 1 && startswith(only(test_args), "jet")

if JET_flag
	@info "Activating the dedicated JET test environment." project=JET_PROJECT
	using Pkg
	Pkg.activate(JET_PROJECT)
	Pkg.instantiate()
end

using TestItemRunner

testfilter = ti -> JET_flag ? (:jet in ti.tags) : !(:jet in ti.tags)

@run_package_tests filter=testfilter

#==============================================================================#
