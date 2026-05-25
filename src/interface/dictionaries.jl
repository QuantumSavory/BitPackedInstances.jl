
#==============================================================================#

@inline function Base.keys(
	bit_pack::PackedInstances
	)

	return PackedInstancesKeysIterator(bit_pack)

end

@inline function Base.values(
	bit_pack::PackedInstances
	)

	return PackedInstancesValuesIterator(bit_pack)

end

@inline function Base.pairs(
	bit_pack::PackedInstances
	)

	return bit_pack

end

@inline function Base.eachindex(
	bit_pack::PackedInstances
	)

	return keys(bit_pack)

end

@inline function Base.keytype(
	::PackedInstances{U, T}
	) where {U <: Unsigned, T <: Tuple}

	return eltype(fieldtypes(T))

end

@inline function Base.valtype(
	::PackedInstances{U, T}
	) where {U <: Unsigned, T <: Tuple}

	return eltype(map(x -> first(instances(x)), fieldtypes(T)))

end

@inline function Base.haskey(
	bit_pack::PackedInstances, key
	)

	return key in keys(bit_pack)

end

@inline function Base.get(
	failure::Base.Callable, bit_pack::PackedInstances, key
	)

	return haskey(bit_pack, key) ? bit_pack[key] : failure()

end

@inline function Base.get(
	bit_pack::PackedInstances, key, default
	)

	return haskey(bit_pack, key) ? bit_pack[key] : default

end

@inline function Base.getkey(
	bit_pack::PackedInstances, key, default
	)

	return ifelse(haskey(bit_pack, key), key, default)

end

#==============================================================================#
