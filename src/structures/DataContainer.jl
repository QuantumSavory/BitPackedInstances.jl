
#==============================================================================#

# Utilised internally to facilitate transformations.
struct _DataContainer{U <: Unsigned, T <: Tuple}

	bits::U

	@inline function _DataContainer(
		bits::U, ::Type{T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(bits)

	end

	@inline function _DataContainer(
		source::_DataContainer{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bits)

	end

end

#==============================================================================#
