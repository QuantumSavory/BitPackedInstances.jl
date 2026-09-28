
#==============================================================================#

# TODO: Eliminate should built-in support become available.
@inline function assume(
	proposition::Bool
	)

	return Core.Intrinsics.llvmcall(
		(
		"""
		declare void @llvm.assume(i1)

		define void @entry(i8) alwaysinline
		{
			%proposition = trunc i8 %0 to i1
			call void @llvm.assume(i1 %proposition)
			ret void
		}
		""",
		"entry"
			),
		Nothing, Tuple{Bool}, proposition
		)

end

#==============================================================================#
