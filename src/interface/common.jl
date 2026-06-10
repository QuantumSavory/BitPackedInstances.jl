
#==============================================================================#

#===============================================================================
COPY
===============================================================================#

@inline function Base.copy(
	keys_iterator::PackedInstancesKeysIterator
	)

	return PackedInstancesKeysIterator(keys_iterator)

end

@inline function Base.copy(
	values_iterator::PackedInstancesValuesIterator
	)

	return PackedInstancesValuesIterator(values_iterator)

end

@inline function Base.copy(
	bit_pack::PackedInstances
	)

	return PackedInstances(bit_pack)

end

@inline function Base.copy(
	bit_pack_container::PackedInstancesContainer
	)

	return PackedInstancesContainer(bit_pack_container)

end

#===============================================================================
LENGTH
===============================================================================#

@inline function Base.length(
	::PackedInstancesKeysIterator{T}
	) where {T <: Tuple}

	return length(fieldtypes(T))

end

@inline function Base.length(
	::PackedInstancesValuesIterator{U, T}
	) where {U <: Unsigned, T <: Tuple}

	return length(fieldtypes(T))

end

@inline function Base.length(
	::PackedInstances{U, T}
	) where {U <: Unsigned, T <: Tuple}

	return length(fieldtypes(T))

end

#===============================================================================
ELTYPE
===============================================================================#

@inline function Base.eltype(
	::PackedInstancesKeysIterator{T}
	) where {T <: Tuple}

	return eltype(fieldtypes(T))

end

@inline function Base.eltype(
	::PackedInstancesValuesIterator{U, T}
	) where {U <: Unsigned, T <: Tuple}

	return eltype(map(x -> first(instances(x)), fieldtypes(T)))

end

@inline function Base.eltype(
	bit_pack::PackedInstances
	)

	return Pair{keytype(bit_pack), valtype(bit_pack)}

end

#===============================================================================
EQUALITY
===============================================================================#

@inline function Base.:(==)(
	left::PackedInstancesKeysIterator, right::PackedInstancesKeysIterator
	)

	return length(left) == length(right) &&
		all(x -> first(x) == last(x), zip(left, right))

end

@inline function Base.:(==)(
	left::PackedInstancesValuesIterator, right::PackedInstancesValuesIterator
	)

	return length(left) == length(right) &&
		all(x -> first(x) == last(x), zip(left, right))

end

@inline function Base.:(==)(
	left::PackedInstances, right::PackedInstances
	)

	return values(left) == values(right)

end

@inline function Base.:(==)(
	left::PackedInstancesContainer, right::PackedInstancesContainer
	)

	return PackedInstances(left) == PackedInstances(right)

end

#===============================================================================
HASH
===============================================================================#

@inline function Base.hash(
	keys_iterator::PackedInstancesKeysIterator, admixture::UInt
	)

	output = hash(PackedInstancesKeysIterator, admixture)
	for key in keys_iterator
		output = hash(key, output)
	end
	return output

end

@inline function Base.hash(
	values_iterator::PackedInstancesValuesIterator, admixture::UInt
	)

	output = hash(PackedInstancesValuesIterator, admixture)
	for value in values_iterator
		output = hash(value, output)
	end
	return output

end

@inline function Base.hash(
	bit_pack::PackedInstances, admixture::UInt
	)

	output = hash(PackedInstances, admixture)
	for (_, value) in bit_pack
		output = hash(value, output)
	end
	return output

end

@inline function Base.hash(
	bit_pack_container::PackedInstancesContainer, admixture::UInt
	)

	output = hash(PackedInstancesContainer, admixture)
	for (_, value) in PackedInstances(bit_pack_container)
		output = hash(value, output)
	end
	return output

end

#==============================================================================#
