
#==============================================================================#

"""

`wrap(::PackedInstances)`

Transforms the data of the provided [`PackedInstances`](@ref) into an immutable
form so as to facilitate utilising it in conjunctin with JuliaGPU kernels.

See also:
	[`unwrap`](@ref)

```jldoctest

julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> bit_pack = PackedInstances(UInt8, north, alpha);

julia> bit_pack == unwrap(wrap(bit_pack))
true

```

"""
@inline function wrap(
	bit_pack::PackedInstances
	)

	return PackedInstancesContainer(bit_pack)

end

"""

`unwrap(::PackedInstancesContainer)`

Transforms the data of the provided [`PackedInstancesContainer`](@ref) back
into its original mutable form so as to facilitate utilising it in conjunctin
with JuliaGPU kernels.

See also:
	[`wrap`](@ref)

```jldoctest

julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> bit_pack = PackedInstances(UInt8, north, alpha);

julia> bit_pack == unwrap(wrap(bit_pack))
true

```

"""
@inline function unwrap(
	bit_pack_container::PackedInstancesContainer
	)

	return PackedInstances(bit_pack_container)

end

"""

`match_value(::PackedInstances, value)`

Optimised value matching suitable for constant folding during compilation.

```jldoctest

julia> @enum Elements begin water; earth; fire; air; end

julia> bit_pack = PackedInstances(UInt8, fire);

julia> match_value(bit_pack, fire)
true

```

"""
@inline @generated function match_value(
	bit_pack::PackedInstances{U, T}, value::X
	) where {U <: Unsigned, T <: Tuple, X}

	content = fieldtypes(T)
	search_success = false
	shift = zero(U)

	for variety in content
		search_success = variety == X
		search_success && break
		shift += convert(U, required_bits(variety))
	end

	search_success || throw(KeyError(X))

	if iszero(required_bits(X))
		output = quote
			return true
			end
	else
		mask = mask_bit_range(U, required_bits(X), shift)
		output = quote
			return bit_pack.bits & $mask ==
				bits_from_value(U, value, Val($shift))
			end
	end

	return output

end

"""

`discard(::PackedInstances, ::Type...)`

Generates a new [`PackedInstances`](@ref) wherein the provided types have been
removed, if possible, or disregarded otherwise.

```jldoctest

julia> @enum Bases begin binary; octal; decimal; hexadecimal; end

julia> bit_pack = PackedInstances(UInt8);

julia> haskey(bit_pack, Function)
false

julia> bit_pack = discard(bit_pack, Function);

julia> haskey(bit_pack, Function)
false

julia> bit_pack = PackedInstances(bit_pack, hexadecimal);

julia> haskey(bit_pack, Bases)
true

julia> bit_pack = discard(bit_pack, Bases);

julia> haskey(bit_pack, Bases)
false

```

"""
@inline @generated function discard(
	bit_pack::PackedInstances{U, T}, keys::Type...
	) where {U <: Unsigned, T <: Tuple}

	existing_data_types = fieldtypes(T)
	# Eliminate redundancy and Type{X} wrapper.
	discarded_data_types = unique(unwrap_type.(collect(keys)))
	# Retain only pertinent data.
	discarded_data_types =
		filter!(in(existing_data_types), discarded_data_types)
	data_types = filter(!in(discarded_data_types), existing_data_types)
	tuple_type = Tuple{data_types...}

	if isempty(discarded_data_types)
		# Discard nothing.
		return quote
			return PackedInstances(bit_pack)
			end
	elseif isempty(data_types)
		# Discard everything.
		return quote
			data_container = _DataContainer(zero(U), Tuple{})
			return PackedInstances(data_container)
			end
	elseif iszero(sum(required_bits.(discarded_data_types); init = zero(U)))
		# No need to worry about overflow as discard is contained in existing.
		# Whatever is being discarded is encoded with nil bits.
		return quote
			data_container = _DataContainer(bit_pack.bits, $tuple_type)
			return PackedInstances(data_container)
			end
	end

	#===========================================================================
	HENCEFORTH, THERE EXISTS AT LEAST TWO SEGMENTS.
	===========================================================================#

	# Group contiguous sections of bits together. Mark kept segments as true.
	segment_varieties = falses(length(existing_data_types))
	segment_shifts = zeros(U, length(existing_data_types))
	varieties_index = firstindex(segment_varieties)
	shifts_index = firstindex(segment_shifts)

	current_variety = !(first(existing_data_types) in discarded_data_types)
	shift = zero(U)
	for data_type in existing_data_types
		span = convert(U, required_bits(data_type))
		iszero(span) && continue
		variety = !(data_type in discarded_data_types)
		if variety != current_variety
			@inbounds segment_varieties[varieties_index] = current_variety
			@inbounds segment_shifts[shifts_index] = shift
			varieties_index = nextind(segment_varieties, varieties_index)
			shifts_index = nextind(segment_shifts, shifts_index)
			current_variety = variety
			shift = zero(U)
		end
		shift += span
	end
	# Mark down the final segment.
	@inbounds segment_varieties[varieties_index] = current_variety
	@inbounds segment_shifts[shifts_index] = shift

	# Utilised in setting up the output bits.
	shift = popfirst!(segment_shifts)
	mask = mask_bit_range(U, shift)

	if varieties_index == nextind(
		segment_varieties, firstindex(segment_varieties)
		)

		# Either KEEP DISCARD or DISCARD KEEP
		if first(segment_varieties)
			return quote
				data_container = _DataContainer(
					bit_pack.bits & $mask, $tuple_type
					)
				return PackedInstances(data_container)
				end
		else
			return quote
				data_container = _DataContainer(
					bit_pack.bits >> $shift, $tuple_type
					)
				return PackedInstances(data_container)
				end
		end

	end

	#===========================================================================
	HENCEFORTH, THERE EXISTS AT LEAST THREE SEGMENTS.
	===========================================================================#

	if popfirst!(segment_varieties)
		output = quote
			bits = bit_pack.bits & $mask
			end
		read_shift = shift
		write_shift = shift
	else
		output = quote
			bits = bit_pack.bits >> $shift
			end
		read_shift = shift
		# Next segment is guaranteed to be true, just take its shift.
		shift, _ = (popfirst!(segment_shifts), popfirst!(segment_varieties))
		mask = mask_bit_range(U, shift)
		output = quote
			$output
			bits &= $mask
			end
		read_shift += shift
		write_shift = shift
	end

	for (span, variety) in zip(segment_shifts, segment_varieties)
		iszero(span) && break
		if variety
			mask = mask_bit_range(U, span, read_shift)
			delta = read_shift - write_shift
			output = quote
				$output
				bits |= (bit_pack.bits & $mask) >> $delta
				end
			write_shift += span
		end
		read_shift += span
	end

	return quote
		$output
		data_container = _DataContainer(bits, $tuple_type)
		return PackedInstances(data_container)
		end

end

"""

`is_encodable(::Type)`

Queries whether [`PackedInstances`](@ref) can be utilised to encode the
instances of the provided argument.

!!! warning
	World age considerations can imply that the output is not stable.

See also:
	[`can_encode`](@ref),
	[`encoding_bits`](@ref)

```jldoctest

julia> @enum GermanMathematicians begin Gauss; Riemann; Hilbert; Noether; end

julia> is_encodable(GermanMathematicians)
true

julia> is_encodable(Expr)
false

```

"""
@inline function is_encodable(
	X::Type
	)

	output = false
	try
		# Verifies whether `@generated` functions are operational.
		value_from_bits(X, UInt(0x0), Val(0x0))
		output = true
	catch
		# Nothing need be done here.
	end
	return output

end

"""

`can_encode(::Union{PackedInstances, Type{PackedInstances}}, ::Type)`

Queries whether the provided [`PackedInstances`](@ref) argument is indeed able
to encode the accompanying type.

!!! warning
	World age considerations can imply that the output is not stable.

See also:
	[`is_encodable`](@ref),
	[`encoding_bits`](@ref)

```jldoctest

julia> @enum FrenchMathematicians begin Cauchy; Laplace; Poincare; Cartan; end

julia> bit_pack = PackedInstances(UInt);

julia> can_encode(bit_pack, FrenchMathematicians)
true

julia> bit_pack = PackedInstances(bit_pack, Cartan);

julia> can_encode(bit_pack, FrenchMathematicians)
true

julia> can_encode(bit_pack, Nothing)
false

```

"""
@inline function can_encode(
	::Union{PackedInstances{U, T}, Type{PackedInstances{U, T}}}, X::Type
	) where {U <: Unsigned, T <: Tuple}

	available_bits = bit_count(U) - convert(
		U, sum(required_bits.(fieldtypes(T)); init = zero(U))
		)
	output = false
	try
		# Verifies whether `@generated` functions are operational.
		value_from_bits(X, UInt(0x0), Val(0x0))
		output = X in fieldtypes(T) || required_bits(X) <= available_bits
	catch
		# Nothing need be done here.
	end
	return output

end

"""

`encoding_bits(::Type)`

Queries how many bits are consumed by [`PackedInstances`](@ref) in encoding
the instances of the provided argument.

!!! warning
	Returns `missing` if encoding is not permissible.

See also:
	[`is_encodable`](@ref),
	[`can_encode`](@ref)

```jldoctest

julia> @enum GreekMathematicians begin Archimedes; Euclid; Pythagoras; end

julia> encoding_bits(GreekMathematicians) == 2
true

julia> ismissing(encoding_bits(Symbol))
true

```

"""
@inline function encoding_bits(
	X::Type
	)

	output = missing
	try
		# Verifies whether `@generated` functions are operational.
		value_from_bits(X, UInt(0x0), Val(0x0))
		output = required_bits(X)
	catch
		# Nothing need be done here.
	end
	return output

end

"""

`encoding_type(::Union{PackedInstances, Type{PackedInstances}})`

Queries the underlying unsigned type that is being utilised by the provided
[`PackedInstances`](@ref) in encoding its content.

```jldoctest

julia> bit_pack = PackedInstances(UInt8);

julia> encoding_type(bit_pack)
UInt8

julia> bit_pack = PackedInstances(UInt32, bit_pack);

julia> encoding_type(bit_pack)
UInt32

```

"""
@inline function encoding_type(
	::Union{PackedInstances{U}, Type{PackedInstances{U}}}
	) where {U <: Unsigned}

	return U

end

"""

`consumed_capacity(::Union{PackedInstances, Type{PackedInstances}})`

Queries the number of consumed bits that are being utilised by the provided
[`PackedInstances`](@ref) in encoding its content.

See also:
	[`available_capacity`](@ref)

```jldoctest

julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> bit_pack = PackedInstances(UInt32, north, alpha);

julia> consumed_capacity(bit_pack) == 4
true

```

"""
@inline function consumed_capacity(
	::Union{PackedInstances{U, T}, Type{PackedInstances{U, T}}}
	) where {U <: Unsigned, T <: Tuple}

	return convert(U, sum(required_bits.(fieldtypes(T)); init = zero(U)))

end

"""

`available_capacity(::Union{PackedInstances, Type{PackedInstances}})`

Queries the number of available bits that can be utilised by the provided
[`PackedInstances`](@ref) in encoding additional content.

See also:
	[`consumed_capacity`](@ref)

```jldoctest

julia> @enum CardinalDirections begin east; north; west; south; end

julia> @enum ColourChannels begin red; green; blue; alpha; end

julia> bit_pack = PackedInstances(UInt32, north, alpha);

julia> available_capacity(bit_pack) == 28
true

```

"""
@inline function available_capacity(
	::Union{PackedInstances{U, T}, Type{PackedInstances{U, T}}}
	) where {U <: Unsigned, T <: Tuple}

	return bit_count(U) - convert(
		U, sum(required_bits.(fieldtypes(T)); init = zero(U))
		)

end

#==============================================================================#
