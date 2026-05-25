
#==============================================================================#

#===============================================================================
ITERATE
===============================================================================#

@inline function Base.iterate(
	::PackedInstancesKeysIterator{T},
	state::Integer = firstindex(fieldtypes(T))
	) where {T <: Tuple}

	content = canonical_form(fieldtypes(T))
	@inbounds output =
		(state in eachindex(content)) ?
		(
			content[state],
			nextind(content, state)
		) :
		nothing
	return output

end

@inline function Base.iterate(
	values_iterator::PackedInstancesValuesIterator{U, T},
	state::Integer = firstindex(fieldtypes(T))
	) where {U <: Unsigned, T <: Tuple}

	content = canonical_form(fieldtypes(T))
	@inbounds output =
		(state in eachindex(content)) ?
		(
			values_iterator.bit_pack[][content[state]],
			nextind(content, state)
		) :
		nothing
	return output

end

@inline function Base.iterate(
	bit_pack::PackedInstances{U, T},
	state::Integer = firstindex(fieldtypes(T))
	) where {U <: Unsigned, T <: Tuple}

	content = canonical_form(fieldtypes(T))
	@inbounds output =
		(state in eachindex(content)) ?
		(
			(content[state], bit_pack[content[state]]),
			nextind(content, state)
		) :
		nothing
	return output

end

@inline function Base.iterate(
	::Iterators.Reverse{
		PackedInstancesKeysIterator{T}
		},
	state::Integer = lastindex(fieldtypes(T))
	) where {T <: Tuple}

	content = canonical_form(fieldtypes(T))
	@inbounds output =
		(state in eachindex(content)) ?
		(
			content[state],
			prevind(content, state)
		) :
		nothing
	return output

end

@inline function Base.iterate(
	values_iterator::Iterators.Reverse{
		PackedInstancesValuesIterator{U, T}
		},
	state::Integer = lastindex(fieldtypes(T))
	) where {U <: Unsigned, T <: Tuple}

	content = canonical_form(fieldtypes(T))
	@inbounds output =
		(state in eachindex(content)) ?
		(
			values_iterator.itr.bit_pack[][content[state]],
			prevind(content, state)
		) :
		nothing
	return output

end

@inline function Base.iterate(
	bit_pack::Iterators.Reverse{
		PackedInstances{U, T}
		},
	state::Integer = lastindex(fieldtypes(T))
	) where {U <: Unsigned, T <: Tuple}

	content = canonical_form(fieldtypes(T))
	@inbounds output =
		(state in eachindex(content)) ?
		(
			(content[state], bit_pack.itr[content[state]]),
			prevind(content, state)
		) :
		nothing
	return output

end

#===============================================================================
ISDONE
===============================================================================#

@inline function Base.isdone(
	::PackedInstancesKeysIterator{T},
	state::Integer = firstindex(fieldtypes(T))
	) where {T <: Tuple}

	return !(state in eachindex(fieldtypes(T)))

end

@inline function Base.isdone(
	::PackedInstancesValuesIterator{U, T},
	state::Integer = firstindex(fieldtypes(T))
	) where {U <: Unsigned, T <: Tuple}

	return !(state in eachindex(fieldtypes(T)))

end

@inline function Base.isdone(
	::PackedInstances{U, T},
	state::Integer = firstindex(fieldtypes(T))
	) where {U <: Unsigned, T <: Tuple}

	return !(state in eachindex(fieldtypes(T)))

end

@inline function Base.isdone(
	::Iterators.Reverse{
		PackedInstancesKeysIterator{T}
		},
	state::Integer = lastindex(fieldtypes(T))
	) where {T <: Tuple}

	return !(state in eachindex(fieldtypes(T)))

end

@inline function Base.isdone(
	::Iterators.Reverse{
		PackedInstancesValuesIterator{U, T}
		},
	state::Integer = lastindex(fieldtypes(T))
	) where {U <: Unsigned, T <: Tuple}

	return !(state in eachindex(fieldtypes(T)))

end

@inline function Base.isdone(
	::Iterators.Reverse{
		PackedInstances{U, T}
		},
	state::Integer = lastindex(fieldtypes(T))
	) where {U <: Unsigned, T <: Tuple}

	return !(state in eachindex(fieldtypes(T)))

end

#==============================================================================#
