
#==============================================================================#

function test_randomised(
	round_count::Unsigned,
	types_to_sample::Base.AbstractVecOrTuple,
	types_to_avoid::Base.AbstractVecOrTuple
	)

	# Utilised extensively throughout.
	type_count = length(types_to_sample)
	interval = Base.OneTo(type_count)

	for _ in Base.OneTo(round_count)

		# Random length sequence of randomly selected types.
		selection_count = rand(interval)
		leftover, selected = Base.split_rest(
			randperm(type_count), selection_count
			)
		@inbounds selected_types = types_to_sample[selected]
		@inbounds leftover_types = types_to_sample[leftover]

		# Sets the baseline for further tests.
		content = map(x -> rand(instances(x)), selected_types)
		reference_bit_pack = PackedInstances(UInt64, content...)

		# Baseline functionality.
		@test begin
			keys_iterator = keys(reference_bit_pack)
			values_iterator = values(reference_bit_pack)
			new_type = rand(types_to_avoid)

			output = keys_iterator == eachindex(reference_bit_pack)
			output &= keytype(reference_bit_pack) == eltype(selected_types)
			output &= valtype(reference_bit_pack) == eltype(content)
			output &= all(in(selected_types), keys_iterator)
			output &= all(in(content), values_iterator)
			output &= length(selected_types) == length(keys_iterator)
			output &= length(content) == length(values_iterator)
			output &= all(
				in(Symbol.(selected_types)),
				propertynames(reference_bit_pack)
				)

			output &= first(content) == get(
				identity, reference_bit_pack, first(selected_types)
				)
			output &= get(reference_bit_pack, new_type, true)
			output &= getkey(reference_bit_pack, new_type, true)

			output &= !isnothing(copy(keys_iterator))
			output &= !isnothing(copy(values_iterator))
			output &= !isnothing(copy(reference_bit_pack))
			output &= !isnothing(copy(wrap(reference_bit_pack)))

			# Certain execution paths are guarded by the calling routine.
			output &= all(
				x -> first(x) || isone(last(x)),
				BitPackedInstances.check_arithmetic_progression.(
					selected_types
					)
				)
			@inbounds selected_singletons = selected_types[
				isone.(length.(instances.(selected_types)))
				]
			output &= all(
				x -> zero(UInt64) === BitPackedInstances.bits_from_value(
					UInt64, first(instances(x)), Val(0x0)
					),
				selected_singletons
				)
		end

		# Permutation invariance.
		@test begin
			@inbounds permuted = PackedInstances(
				UInt64, content[randperm(selection_count)]...
				)

			output = reference_bit_pack == permuted
			output &= reference_bit_pack == unwrap(wrap(permuted))
			output &= wrap(reference_bit_pack) == wrap(permuted)
			output &= keys(reference_bit_pack) == keys(permuted)
			output &= values(reference_bit_pack) == values(permuted)
			output &= eltype(reference_bit_pack) == Pair{
				keytype(permuted), valtype(permuted)
				}

			output &=
				hash(keys(reference_bit_pack)) == hash(keys(permuted))
			output &=
				hash(values(reference_bit_pack)) == hash(values(permuted))
			output &=
				hash(reference_bit_pack) == hash(permuted)
			output &=
				hash(wrap(reference_bit_pack)) == hash(wrap(permuted))
		end

		# Either encode directly or start vacant and then augment.
		@test begin
			vacant = PackedInstances(UInt64)
			full = PackedInstances(vacant, content...)
			vacant.bits = xor(one(UInt64), vacant.bits)
			isone(vacant.bits) && reference_bit_pack == full
		end

		# Either encode directly or encode partially and then augment.
		@test begin
			now, later = Base.split_rest(
				randperm(selection_count), rand(Base.OneTo(selection_count))
				)
			@inbounds partial = PackedInstances(UInt64, content[now]...)
			@inbounds complete = PackedInstances(partial, content[later]...)
			reference_bit_pack == complete
		end

		# Overwrite some values.
		@test begin
			# Bernoulli sampling.
			overwritten_types = randsubseq(selected_types, 0.5)
			new_content = map(x -> rand(instances(x)), overwritten_types)
			bulk_modified = PackedInstances(reference_bit_pack, new_content...)
			individually_modified = copy(reference_bit_pack)
			for (key, value) in zip(overwritten_types, new_content)
				individually_modified[key] = value
			end
			output = bulk_modified == individually_modified
			for (key, value) in reference_bit_pack
				clause = !(key in overwritten_types) &&
					bulk_modified[key] == value
				@inbounds clause |= (key in overwritten_types) &&
					bulk_modified[key] == new_content[
						findfirst(==(key), overwritten_types)
						]
				output &= clause
			end
			output
		end

		# Discard some values.
		@test begin
			# Bernoulli sampling.
			discarded_types = randsubseq(selected_types, 0.5)
			partial = discard(reference_bit_pack, discarded_types...)
			output = length(partial) <= length(reference_bit_pack)
			for (key, value) in reference_bit_pack
				clause = !(key in discarded_types) && partial[key] == value
				clause |= (key in discarded_types) && !haskey(partial, key)
				output &= clause
			end
			output
		end

		# Type invariance.
		@test begin
			consumed = consumed_capacity(reference_bit_pack)
			available = available_capacity(reference_bit_pack)
			output = UInt64 == encoding_type(reference_bit_pack)
			output &= 0x40 == consumed + available
			if consumed <= 0x10
				shrunk = PackedInstances(UInt16, reference_bit_pack)

				output &= reference_bit_pack == shrunk
				output &= reference_bit_pack == unwrap(wrap(shrunk))
				output &= wrap(reference_bit_pack) == wrap(shrunk)
				output &= keys(reference_bit_pack) == keys(shrunk)
				output &= values(reference_bit_pack) == values(shrunk)
				output &= eltype(reference_bit_pack) == Pair{
					keytype(shrunk), valtype(shrunk)
					}

				output &=
					hash(keys(reference_bit_pack)) == hash(keys(shrunk))
				output &=
					hash(values(reference_bit_pack)) == hash(values(shrunk))
				output &=
					hash(reference_bit_pack) == hash(shrunk)
				output &=
					hash(wrap(reference_bit_pack)) == hash(wrap(shrunk))

				output &= UInt16 == encoding_type(shrunk)
				output &=
					0x10 ==
						consumed_capacity(shrunk) + available_capacity(shrunk)
			end
			output
		end

		# Access mechanism invariance.
		if !isempty(selected_types)
			@test begin
			new_content = map(x -> rand(instances(x)), selected_types)
			via_index = copy(reference_bit_pack)
			via_property = copy(reference_bit_pack)

			output = all(
				x ->
					getproperty(reference_bit_pack, first(x)) ==
						reference_bit_pack[last(x)],
				zip(Symbol.(selected_types), selected_types)
				)

			for (property_name, key, value) in zip(
				Symbol.(selected_types), selected_types, new_content
				)
				via_index[key] = value
				setproperty!(via_property, property_name, value)
			end

			output &= via_index == via_property
			end
		end

		# Potential accidents that may transpire.
		if consumed_capacity(reference_bit_pack) > 0x8
			@test begin
				bit_flip = copy(reference_bit_pack)
				bit_flip.bits = xor(
					one(bit_flip.bits), bit_flip.bits & one(bit_flip.bits)
					)
				reference_bit_pack != bit_flip
			end
			@test_throws ArgumentError begin
				PackedInstances(UInt8, content...)
			end
			@test_throws ArgumentError begin
				empty = PackedInstances(UInt8)
				PackedInstances(empty, content...)
			end
			@test_throws ArgumentError begin
				PackedInstances(UInt8, reference_bit_pack)
			end
		end

		# Augment with additional content if possible.
		if !isempty(leftover_types)
			@test begin
				consumed = consumed_capacity(reference_bit_pack)
				new_type = rand(leftover_types)
				new_value = rand(instances(new_type))
				augmented = PackedInstances(reference_bit_pack, new_value)
				consumed_capacity(augmented) ==
					consumed + encoding_bits(new_type)
			end

			# This displays an error message in the logs, perfectly benign.
			@test_throws KeyError begin
				new_type = rand(leftover_types)
				new_value = rand(instances(new_type))
				bit_pack = copy(reference_bit_pack)
				@info "The following error message is intentional."
				bit_pack[new_type] = new_value
			end
		end

		# Joint iterator correctness.
		@test begin
			keys_iterator = keys(reference_bit_pack)
			values_iterator = values(reference_bit_pack)
			pairs_iterator = pairs(reference_bit_pack)
			# Both forwards and backwards.
			if rand(Bool)
				keys_iterator = Iterators.reverse(keys_iterator)
				values_iterator = Iterators.reverse(values_iterator)
				pairs_iterator = Iterators.reverse(pairs_iterator)
			end
			output = eltype(reference_bit_pack) == Pair{
				eltype(keys(reference_bit_pack)),
				eltype(values(reference_bit_pack))
				}
			for (key, value, key_value) in zip(
				keys_iterator, values_iterator, pairs_iterator
				)
				output &= key == first(key_value) && value == last(key_value)
				output &= match_value(reference_bit_pack, value)
			end
			output
		end

		# Always handled properly, be it naughty or nice.
		if rand(Bool)
			@test begin
				new_type = rand(types_to_avoid)
				output = !is_encodable(new_type)
				output &= !can_encode(reference_bit_pack, new_type)
				output &= ismissing(encoding_bits(new_type))
			end

			@test_throws KeyError begin
				new_type = rand(types_to_avoid)
				reference_bit_pack[new_type]
			end
		else
			@test begin
				new_type = rand(types_to_sample)
				output = is_encodable(new_type)
				output &= can_encode(reference_bit_pack, new_type)
				output &= !ismissing(encoding_bits(new_type))
			end
		end

	end

end

#==============================================================================#
