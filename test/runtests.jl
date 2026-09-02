#!/usr/bin/env julia
#==============================================================================#

# Satisfy own dependencies when executed as a script.
if abspath(PROGRAM_FILE) == @__FILE__
	import Pkg
	Pkg.activate(@__DIR__)
	Pkg.instantiate()
end

using TestItemRunner: @testmodule, @testitem, @run_package_tests

include("argument_parsing/query.jl")

@inline function run_tests(
	arguments::Base.AbstractVecOrTuple{<: AbstractString}
	)

	enabled_tags = query_enabled_tags(arguments)

	@inline function item_filter(
		item
		)

		return all(in(enabled_tags), item.tags)

	end

	@run_package_tests filter = item_filter
	return nothing

end

function main(
	ARGS::Base.AbstractVecOrTuple{<: AbstractString}
	)

	# Either executed as a script or invoked through package test procedure.
	if abspath(PROGRAM_FILE) == @__FILE__
		run_tests(ARGS)
	else
		# Disable static analysis by default.
		# TODO: Revisit once JET ceases being a problem on nightly builds.
		run_tests(isempty(ARGS) ? ["disable", "--static_analysis"] : ARGS)
	end

	exit()

end

@main

#==============================================================================#
