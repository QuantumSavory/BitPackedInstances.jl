
#==============================================================================#

@testmodule DependencyManager begin

	import Pkg

	function satisfy_dependencies(
		path::AbstractString
		)

		Pkg.activate(normpath(path))
		Pkg.instantiate()
		return nothing

	end

end

#==============================================================================#
