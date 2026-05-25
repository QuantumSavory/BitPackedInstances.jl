
#==============================================================================#

"""

`PackedInstancesContainer(::PackedInstances)`

Transforms the data of the provided [`PackedInstances`](@ref) into an immutable
form so as to facilitate utilising it in conjunctin with JuliaGPU kernels.

!!! warning
	It is advised that one ought to avoid utilising this type directly, in lieu
	consider employing the ['wrap'](@ref) and [`unwrap`](@ref) invocations.

"""
struct PackedInstancesContainer{U <: Unsigned, T <: Tuple}

	bits::U

	@inline function PackedInstancesContainer(
		source::_DataContainer{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bits)

	end

	@inline function PackedInstancesContainer(
		source::PackedInstancesContainer{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bits)

	end

end

#==============================================================================#
