
#==============================================================================#

#===============================================================================
ITERATORS
===============================================================================#

function Base.show(
	io::IO,
	iterator::Union{
		PackedInstancesKeysIterator, PackedInstancesValuesIterator
		},
	minimum_elements::Unsigned = 0x8
	)

	if get(io, :compact, false) || isempty(iterator)
		output = ifelse(
			iterator isa PackedInstancesKeysIterator,
			"PackedInstancesKeysIterator",
			"PackedInstancesValuesIterator"
			)
	else
		# Mimicing the base library behaviour.
		output = ""
		first_entry = true
		counter = ifelse(
			get(io, :limited, false),
			minimum_elements,
			length(iterator)
			)
		# Nested elements should present themselves succinctly.
		succinct_io = IOContext(io, :compact => true, :limited => true)

		for element in iterator
			prefix = ifelse(first_entry, "", ", ")
			first_entry = false
			if iszero(counter)
				output *= prefix * "…"
				break
			else
				output *= prefix * repr(element; context = succinct_io)
			end
			counter -= one(counter)
		end

		output = "[$output]"
	end

	print(io, output)
	return nothing

end

@eval function Base.show(
	io::IO,
	::MIME"text/plain",
	iterator::Union{
		PackedInstancesKeysIterator, PackedInstancesValuesIterator
		},
	minimum_elements::Unsigned = 0x8
	)

	count = length(iterator)
	# This is silly but no edge case shall be left unaccounted for.
	singular_or_plural = ifelse(isone(count), "entry", "entries")
	output = ifelse(
		iterator isa PackedInstancesKeysIterator,
		"PackedInstancesKeysIterator",
		"PackedInstancesValuesIterator"
		)
	output *= " encoding $count $singular_or_plural"

	if get(io, :compact, false) || isempty(iterator)
		output *= "."
	else
		output *= ":"

		height, width = Unsigned.(displaysize(io))
		if width < 0x20
			# Pathologically tiny.
			output *= ifelse(width < 0x10, "\n⋮", "\n  ⋮")
		else
			# Leave one tab width free on either side.
			width = width - 0x8
			# Saturate to three quarters of the height at most.
			counter = ifelse(
				get(io, :limited, false),
				max(minimum_elements, 0x3 * (height >> 0x2)),
				count
				)

			# Nested elements should present themselves succinctly.
			succinct_io = IOContext(io, :compact => true, :limited => true)

			for element in iterator
				if iszero(counter)
					output *= "\n    ⋮"
					break
				else
					element_repr = repr(element; context = succinct_io)
					# Truncate overwhelmingly long lines.
					if length(element_repr) > width
						# Retain some space for the dots.
						element_repr = first(element_repr, width - 0x1)
						element_repr *= "…"
					end
					output *= "\n    " * element_repr
				end
				counter -= one(counter)
			end
		end
	end

	print(io, output)
	return nothing

end

#===============================================================================
PACKEDINSTANCES
===============================================================================#

function Base.show(
	io::IO,
	input::Union{
		PackedInstances, PackedInstancesContainer
		};
	minimum_elements::Unsigned = 0x8
	)

	bit_pack = PackedInstances(input)
	# Nested elements should present themselves succinctly.
	succinct_io = IOContext(io, :compact => true, :limited => true)
	type_repr = repr(encoding_type(bit_pack); context = succinct_io)

	if get(io, :compact, false)
		output = ifelse(
			input isa PackedInstances,
			"PackedInstances{$type_repr}",
			"PackedInstancesContainer{$type_repr}"
			)
	else
		output = ""
		counter = ifelse(
			get(io, :limited, false),
			minimum_elements,
			length(bit_pack)
			)

		for (_, value) in bit_pack
			if iszero(counter)
				output *= ", …"
				break
			else
				output *= ", " * repr(value; context = succinct_io)
			end
			counter -= one(counter)
		end

		output = ifelse(
			input isa PackedInstances,
			"PackedInstances($type_repr$output)",
			"PackedInstancesContainer(PackedInstances($type_repr$output))"
			)
	end

	print(io, output)
	return nothing

end

function Base.show(
	io::IO,
	::MIME"text/plain",
	input::Union{
		PackedInstances, PackedInstancesContainer
		};
	minimum_elements::Unsigned = 0x8
	)

	bit_pack = PackedInstances(input)
	count = length(bit_pack)
	# This is silly but no edge case shall be left unaccounted for.
	singular_or_plural = ifelse(isone(count), "entry", "entries")

	# Nested elements should present themselves succinctly.
	succinct_io = IOContext(io, :compact => true, :limited => true)
	type_repr = repr(encoding_type(bit_pack); context = succinct_io)
	output = ifelse(
		input isa PackedInstances,
		"PackedInstances{$type_repr}",
		"PackedInstancesContainer{$type_repr}"
		)
	output *= " encoding $count $singular_or_plural"

	if get(io, :compact, false) || isempty(bit_pack)
		output *= "."
	else
		output *= ":"

		height, width = Unsigned.(displaysize(io))
		if width < 0x20
			# Pathologically tiny.
			output *= ifelse(width < 0x10, "\n⋮ => ⋮", "\n  ⋮  =>  ⋮")
		else
			# Leave one tab width free on either side plus room for arrow.
			width = width - 0x12
			# Utilised for truncation.
			half_width = width >> 0x1
			# Saturate to three quarters of the height at most.
			counter = ifelse(
				get(io, :limited, false),
				max(minimum_elements, 0x3 * (height >> 0x2)),
				count
				)

			for (key, value) in bit_pack
				if iszero(counter)
					output *= "\n    ⋮    =>    ⋮"
					break
				else
					key_repr = repr(key; context = succinct_io)
					value_repr = repr(value; context = succinct_io)
					key_length = length(key_repr)
					value_length = length(value_repr)
					total_length, flag = Base.Checked.add_with_overflow(
						key_length, value_length
						)

					if flag || total_length > width
						# Truncate overwhelmingly long lines.
						if key_length <= half_width
							# Retain some space for the dots.
							value_repr =
								first(value_repr, width - key_length - 0x1)
							value_repr *= "…"
						elseif value_length <= half_width
							# Retain some space for the dots.
							key_repr =
								first(key_repr, width - value_length - 0x1)
							key_repr *= "…"
						else
							# Retain some space for the dots.
							key_repr = first(key_repr, half_width - 0x1)
							value_repr = first(value_repr, half_width - 0x1)
							key_repr *= "…"
							value_repr *= "…"
						end
					end

					output *= "\n    " * key_repr * "    =>    " * value_repr
				end
				counter -= one(counter)
			end
		end
	end

	print(io, output)
	return nothing

end

#==============================================================================#
