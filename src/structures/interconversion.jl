
#==============================================================================#

# TODO: Figure out how to eliminate this extraneous private type.

#===============================================================================
DATACONTAINER
===============================================================================#

@inline function _DataContainer(
	source::Union{PackedInstances{U, T}, PackedInstancesContainer{U, T}}
	) where {U <: Unsigned, T <: Tuple}

	return _DataContainer(source.bits, T)

end

#===============================================================================
PACKEDINSTANCES
===============================================================================#

@inline function PackedInstances(
	bit_pack_container::PackedInstancesContainer
	)

	return PackedInstances(_DataContainer(bit_pack_container))

end

#===============================================================================
PACKEDINSTANCESCONTAINER
===============================================================================#

@inline function PackedInstancesContainer(
	bit_pack::PackedInstances
	)

	return PackedInstancesContainer(_DataContainer(bit_pack))

end

#==============================================================================#
