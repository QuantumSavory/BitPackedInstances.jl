
#==============================================================================#

# Utilised internally to facilitate transformations.
struct _DataContainer{U <: Unsigned, T <: Tuple}

	bits::U

	@inline function _DataContainer(
		bits::U, ::Type{T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(bits)

	end

end

#==============================================================================#
