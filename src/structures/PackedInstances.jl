
#==============================================================================#

"""

`PackedInstances(::Type{<: Unsigned}, values...)`

`PackedInstances(::PackedInstances, values...)`

`PackedInstances(::Type{<: Unsigned}, ::PackedInstances)`

`PackedInstances(::PackedInstancesContainer)`

Densely encodes the provided argument(s) in the accompanying unsigned type for
compact storage and efficient retrieval.

!!! note
	Given that only one `instances` value can be stored for each individual
	type, the constructors select the last encountered such value.

See also:
	[`wrap`](@ref),
	[`unwrap`](@ref),
	[`match_value`](@ref),
	[`discard`](@ref)
	[`is_encodable`](@ref),
	[`can_encode`](@ref),
	[`encoding_bits`](@ref),
	[`encoding_type`](@ref),
	[`consumed_capacity`](@ref),
	[`available_capacity`](@ref)

```jldoctest

julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> bit_pack = PackedInstances(UInt8, north);

julia> bit_pack = PackedInstances(bit_pack, alpha);

julia> bit_pack.CardinalDirections == bit_pack[CardinalDirections]
true

julia> bit_pack.CardinalDirections == north
true

julia> bit_pack[ColourChannels] == alpha
true

julia> bit_pack.CardinalDirections = east;

julia> bit_pack[ColourChannels] = blue;

julia> bit_pack.CardinalDirections == east
true

julia> bit_pack[ColourChannels] == blue
true

```

"""
mutable struct PackedInstances{U <: Unsigned, T <: Tuple}

	bits::U

	@inline function PackedInstances(
		source::_DataContainer{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bits)

	end

	@inline function PackedInstances(
		source::PackedInstances{U, T}
		) where {U <: Unsigned, T <: Tuple}

		return new{U, T}(source.bits)

	end

end

# CAUTION: Requires that argument types support querying their instances.
@inline @generated function PackedInstances(
	::Type{U}, values...
	) where {U <: Unsigned}

	if isempty(values)
		# CAUTION: Handle separately due to clashing with validation.
		return quote
			data_container = _DataContainer(zero(U), Tuple{})
			return PackedInstances(data_container)
			end
	end

	# These are required later for indexable referencing.
	data_types = values
	# Eliminate redundancy.
	unique_data_types = unique(data_types)
	shifts = (required_bits(x) for x in unique_data_types)

	# CAUTION: The summation may potentially overflow, handle it properly.
	sums = accumulate(+, shifts; init = zero(U))
	issorted(sums) && last(sums) <= bit_count(U) ||
		throw(ArgumentError(error_string_construction(U)))

	# Feeds forward into future iterations.
	output = quote
		bits = zero(U)
		end
	shift = zero(U)

	for (span, data_type) in zip(shifts, unique_data_types)
		iszero(span) && continue
		# Latest value overwrites all previous ones.
		value_index = findlast(==(data_type), data_types)
		output = quote
			$output
			@inbounds bits |=
				bits_from_value(U, values[$value_index], Val($shift))
			end
		shift += convert(U, span)
	end

	tuple_type = Tuple{unique_data_types...}
	return quote
		$output
		data_container = _DataContainer(bits, $tuple_type)
		return PackedInstances(data_container)
		end

end

# CAUTION: Requires that argument types support querying their instances.
@inline @generated function PackedInstances(
	bit_pack::PackedInstances{U, T}, values...
	) where {U <: Unsigned, T <: Tuple}

	existing_data_types = fieldtypes(T)
	existing_shifts =
		(convert(U, required_bits(x)) for x in existing_data_types)
	# These are required later for idexable referencing.
	new_data_types = values
	data_types = [existing_data_types..., new_data_types...]
	# Eliminate redundancy.
	data_types = unique!(data_types)

	# CAUTION: The summation may potentially overflow, handle it properly.
	sums = accumulate(
		+, (required_bits(x) for x in data_types); init = zero(U)
		)
	issorted(sums) && last(sums) <= bit_count(U) ||
		throw(ArgumentError(error_string_expansion(U, T)))

	# Smarter masking with fewer operations.
	mask = zero(U)
	shift = zero(U)
	for (span, variety) in zip(existing_shifts, existing_data_types)
		if !iszero(span) && variety in new_data_types
			mask |= mask_bit_range(U, span, shift)
		end
		shift += span
	end
	if iszero(mask)
		output = quote
			bits = bit_pack.bits
			end
	elseif mask == mask_bit_range(U, shift, zero(U))
		output = quote
			bits = zero(U)
			end
	else
		mask = ~mask
		output = quote
			bits = bit_pack.bits & $mask
			end
	end

	# Feeds forward into future iterations.
	suffix_shift = zero(U)

	for data_type in unique(new_data_types)
		span = convert(U, required_bits(data_type))
		iszero(span) && continue
		# Latest value overwrites all previous ones.
		value_index = findlast(==(data_type), new_data_types)

		# Check whether it matches an existing type.
		shift = zero(U)
		search_success = false
		for (span, variety) in zip(existing_shifts, existing_data_types)
			search_success = variety == data_type
			search_success && break
			shift += span
		end

		if !search_success
			# Brand new type, apply suffix then increment it.
			shift += suffix_shift
			suffix_shift += span
		end

		output = quote
			$output
			@inbounds bits |=
				bits_from_value(U, values[$value_index], Val($shift))
			end
	end

	tuple_type = Tuple{data_types...}
	return quote
		$output
		data_container = _DataContainer(bits, $tuple_type)
		return PackedInstances(data_container)
		end

end

# Alter the encoding unsigned type.
@inline function PackedInstances(
	::Type{U_new}, bit_pack::PackedInstances{U, T}
	) where {U_new <: Unsigned, U <: Unsigned, T <: Tuple}

	content = fieldtypes(T)
	sum(
		(required_bits(x) for x in content); init = zero(U)
		) <= bit_count(U_new) ||
			throw(ArgumentError(error_string_conversion(U_new, U, T)))
	data_container = _DataContainer(convert(U_new, bit_pack.bits), T)
	return PackedInstances(data_container)

end

#==============================================================================#

