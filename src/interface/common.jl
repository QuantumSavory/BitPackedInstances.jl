
#==============================================================================#

#===============================================================================
COPY
===============================================================================#

# CAUTION: Proper syntax for nested parametric typing.
@inline function Base.copy(
	input::Union{
		PackedInstancesKeysIterator,
		Iterators.Reverse{<: PackedInstancesKeysIterator}
		}
	)

	if input isa Iterators.Reverse
		direction = Iterators.reverse
		keys_iterator = input.itr
	else
		direction = identity
		keys_iterator = input
	end
	return direction(PackedInstancesKeysIterator(keys_iterator))

end

# CAUTION: Proper syntax for nested parametric typing.
@inline function Base.copy(
	input::Union{
		PackedInstancesValuesIterator,
		Iterators.Reverse{<: PackedInstancesValuesIterator}
		}
	)

	if input isa Iterators.Reverse
		direction = Iterators.reverse
		values_iterator = input.itr
	else
		direction = identity
		values_iterator = input
	end
	return direction(PackedInstancesValuesIterator(values_iterator))

end

# CAUTION: Proper syntax for nested parametric typing.
@inline function Base.copy(
	input::Union{
		PackedInstances,
		Iterators.Reverse{<: PackedInstances}
		}
	)

	if input isa Iterators.Reverse
		direction = Iterators.reverse
		bit_pack = input.itr
	else
		direction = identity
		bit_pack = input
	end
	return direction(PackedInstances(bit_pack))

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
	::Type{PackedInstancesKeysIterator{T}}
	) where {T <: Tuple}

	return eltype(fieldtypes(T))

end

@inline function Base.eltype(
	::Type{PackedInstancesValuesIterator{U, T}}
	) where {U <: Unsigned, T <: Tuple}

	return eltype(map(x -> first(instances(x)), fieldtypes(T)))

end

@inline function Base.eltype(
	::Type{PackedInstances{U, T}}
	) where {U <: Unsigned, T <: Tuple}

	return Pair{
		keytype(PackedInstances{U, T}), valtype(PackedInstances{U, T})
		}

end

#===============================================================================
EQUALITY
===============================================================================#

@inline function Base.:(==)(
	left::PackedInstancesKeysIterator,
	right::PackedInstancesKeysIterator
	)

	return length(left) == length(right) &&
		all(splat(==), zip(left, right))

end

# CAUTION: Proper syntax for nested parametric typing.
@inline function Base.:(==)(
	left::Iterators.Reverse{<: PackedInstancesKeysIterator},
	right::Iterators.Reverse{<: PackedInstancesKeysIterator}
	)

	return length(left.itr) == length(right.itr) &&
		all(splat(==), zip(left.itr, right.itr))

end

@inline function Base.:(==)(
	left::PackedInstancesValuesIterator,
	right::PackedInstancesValuesIterator
	)

	return length(left) == length(right) &&
		all(splat(==), zip(left, right))

end

# CAUTION: Proper syntax for nested parametric typing.
@inline function Base.:(==)(
	left::Iterators.Reverse{<: PackedInstancesValuesIterator},
	right::Iterators.Reverse{<: PackedInstancesValuesIterator}
	)

	return length(left.itr) == length(right.itr) &&
		all(splat(==), zip(left.itr, right.itr))

end

@inline function Base.:(==)(
	left::PackedInstances,
	right::PackedInstances
	)

	return values(left) == values(right)

end

# CAUTION: Proper syntax for nested parametric typing.
@inline function Base.:(==)(
	left::Iterators.Reverse{<: PackedInstances},
	right::Iterators.Reverse{<: PackedInstances}
	)

	return values(left.itr) == values(right.itr)

end

@inline function Base.:(==)(
	left::PackedInstancesContainer,
	right::PackedInstancesContainer
	)

	return PackedInstances(left) == PackedInstances(right)

end

#===============================================================================
HASH
===============================================================================#

# CAUTION: Proper syntax for nested parametric typing.
@inline function Base.hash(
	input::Union{
		PackedInstancesKeysIterator,
		Iterators.Reverse{<: PackedInstancesKeysIterator}
		},
	admixture::UInt
	)

	if input isa Iterators.Reverse
		hashed_type = Iterators.Reverse{PackedInstancesKeysIterator}
		keys_iterator = input.itr
	else
		hashed_type = PackedInstancesKeysIterator
		keys_iterator = input
	end
	output = hash(hashed_type, admixture)
	for key in keys_iterator
		output = hash(key, output)
	end
	return output

end

# CAUTION: Proper syntax for nested parametric typing.
@inline function Base.hash(
	input::Union{
		PackedInstancesValuesIterator,
		Iterators.Reverse{<: PackedInstancesValuesIterator}
		},
	admixture::UInt
	)

	if input isa Iterators.Reverse
		hashed_type = Iterators.Reverse{PackedInstancesValuesIterator}
		values_iterator = input.itr
	else
		hashed_type = PackedInstancesValuesIterator
		values_iterator = input
	end
	output = hash(hashed_type, admixture)
	for value in values_iterator
		output = hash(value, output)
	end
	return output

end

# CAUTION: Proper syntax for nested parametric typing.
@inline function Base.hash(
	input::Union{
		PackedInstances,
		Iterators.Reverse{<: PackedInstances}
		},
	admixture::UInt
	)

	if input isa Iterators.Reverse
		hashed_type = Iterators.Reverse{PackedInstances}
		bit_pack = input.itr
	else
		hashed_type = PackedInstances
		bit_pack = input
	end
	output = hash(hashed_type, admixture)
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
