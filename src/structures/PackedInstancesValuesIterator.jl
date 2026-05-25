
#==============================================================================#

"""

`PackedInstancesValuesIterator(::PackedInstances)`

Iterator over the values of the provided [`PackedInstances`](@ref) argument.

!!! warning
	It is advised that one ought to avoid utilising this type directly, in lieu
	consider employing the 'values' invocation.

See also:	[`PackedInstancesKeysIterator`](@ref)

"""
struct PackedInstancesValuesIterator{U <: Unsigned, T <: Tuple}

	bit_pack::Ref{PackedInstances{U, T}}

	@inline function PackedInstancesValuesIterator(
		bit_pack::PackedInstances{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(Ref(bit_pack))

	end

	@inline function PackedInstancesValuesIterator(
		source::PackedInstancesValuesIterator{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bit_pack)

	end

end

#==============================================================================#
