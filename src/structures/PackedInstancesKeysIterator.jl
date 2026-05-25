
#==============================================================================#

"""

`PackedInstancesKeysIterator(::PackedInstances)`

Iterator over the keys of the provided [`PackedInstances`](@ref) argument.

!!! warning
	It is advised that one ought to avoid utilising this type directly, in lieu
	consider employing the 'keys' invocation.

See also:	[`PackedInstancesValuesIterator`](@ref)

"""
struct PackedInstancesKeysIterator{T <: Tuple}

	@inline function PackedInstancesKeysIterator(
		::PackedInstances{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{T}()

	end

	@inline function PackedInstancesKeysIterator(
		source::PackedInstancesKeysIterator{T}
		) where {T <: Tuple}

		return new{T}()

	end

end

#==============================================================================#
