
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

		# Sets the reference for further tests.
		content = map(x -> rand(instances(x)), selected_types)
		bit_pack = PackedInstances(UInt64, content...)
		reverse_bit_pack = Iterators.reverse(bit_pack)
		keys_iterator = keys(bit_pack)
		reverse_keys = Iterators.reverse(keys_iterator)
		values_iterator = values(bit_pack)
		reverse_values = Iterators.reverse(values_iterator)
		bit_pack_container = wrap(bit_pack)

		# Baseline routines.
		@test begin
			new_type = rand(types_to_avoid)

			output = keys_iterator == eachindex(bit_pack)
			output &= keytype(bit_pack) == eltype(selected_types)
			output &= valtype(bit_pack) == eltype(content)
			output &= all(in(selected_types), keys_iterator)
			output &= all(in(keys_iterator), selected_types)
			output &= all(in(content), values_iterator)
			output &= all(in(values_iterator), content)
			output &= length(selected_types) == length(keys_iterator)
			output &= length(content) == length(values_iterator)
			output &= all(
				in(Symbol.(selected_types)), propertynames(bit_pack)
				)
			output &= all(
				isempty,
				propertynames.(
					(keys_iterator, values_iterator, bit_pack_container)
					)
				)

			output &= first(content) == get(
				identity, bit_pack, first(selected_types)
				)
			output &= get(bit_pack, new_type, true)
			output &= getkey(bit_pack, new_type, true)

			output &= keys_iterator == copy(keys_iterator)
			output &= reverse_keys == copy(reverse_keys)
			output &= values_iterator == copy(values_iterator)
			output &= reverse_values == copy(reverse_values)
			output &= bit_pack == copy(bit_pack)
			output &= reverse_bit_pack == copy(reverse_bit_pack)
			output &= bit_pack_container == copy(bit_pack_container)

			# Certain execution paths are guarded by the calling routine.
			@inbounds selected_singletons = selected_types[
				map(x -> isone(length(instances(x))), selected_types)
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
			reverse_permuted = Iterators.reverse(permuted)
			permuted_keys = keys(permuted)
			reverse_permuted_keys = Iterators.reverse(permuted_keys)
			permuted_values = values(permuted)
			reverse_permuted_values = Iterators.reverse(permuted_values)
			permuted_container = wrap(permuted)

			output = keys_iterator == permuted_keys
			output &= reverse_keys == reverse_permuted_keys
			output &= values_iterator == permuted_values
			output &= reverse_values == reverse_permuted_values
			output &= bit_pack == permuted
			output &= reverse_bit_pack == reverse_permuted
			output &= bit_pack == unwrap(permuted_container)
			output &= bit_pack_container == permuted_container
			output &= eltype(bit_pack) == Pair{
				keytype(permuted), valtype(permuted)
				}

			output &=
				hash(keys_iterator) == hash(permuted_keys)
			output &=
				hash(reverse_keys) == hash(reverse_permuted_keys)
			output &=
				hash(values_iterator) == hash(permuted_values)
			output &=
				hash(reverse_values) == hash(reverse_permuted_values)
			output &=
				hash(bit_pack) == hash(permuted)
			output &=
				hash(reverse_bit_pack) == hash(reverse_permuted)
			output &=
				hash(bit_pack_container) == hash(permuted_container)
		end

		# Either encode directly or start vacant and then augment.
		@test begin
			vacant = PackedInstances(UInt64)
			full = PackedInstances(vacant, content...)
			vacant.bits = xor(one(UInt64), vacant.bits)
			isone(vacant.bits) && bit_pack == full
		end

		# Either encode directly or encode partially and then augment.
		@test begin
			now, later = Base.split_rest(
				randperm(selection_count), rand(Base.OneTo(selection_count))
				)
			@inbounds partial = PackedInstances(UInt64, content[now]...)
			@inbounds complete = PackedInstances(partial, content[later]...)
			bit_pack == complete
		end

		# Overwrite some values.
		@test begin
			# Bernoulli sampling.
			overwritten_types = randsubseq(selected_types, 0.5)
			new_content = map(x -> rand(instances(x)), overwritten_types)
			bulk_modified = PackedInstances(bit_pack, new_content...)
			individually_modified = copy(bit_pack)
			for (key, value) in zip(overwritten_types, new_content)
				individually_modified[key] = value
			end
			output = bulk_modified == individually_modified
			for (key, value) in bit_pack
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
			partial = discard(bit_pack, discarded_types...)
			output = length(partial) <= length(bit_pack)
			for (key, value) in bit_pack
				clause = !(key in discarded_types) && partial[key] == value
				clause |= (key in discarded_types) && !haskey(partial, key)
				output &= clause
			end
			output
		end

		# Type invariance.
		@test begin
			consumed = consumed_capacity(bit_pack)
			available = available_capacity(bit_pack)
			output = UInt64 == encoding_type(bit_pack)
			output &= 0x40 == consumed + available
			if consumed <= 0x10
				shrunk = PackedInstances(UInt16, bit_pack)
				reverse_shrunk = Iterators.reverse(shrunk)
				shrunk_keys = keys(shrunk)
				reverse_shrunk_keys = Iterators.reverse(shrunk_keys)
				shrunk_values = values(shrunk)
				reverse_shrunk_values = Iterators.reverse(shrunk_values)
				shrunk_container = wrap(shrunk)

				output &= keys_iterator == shrunk_keys
				output &= reverse_keys == reverse_shrunk_keys
				output &= values_iterator == shrunk_values
				output &= reverse_values == reverse_shrunk_values
				output &= bit_pack == shrunk
				output &= reverse_bit_pack == reverse_shrunk
				output &= bit_pack == unwrap(shrunk_container)
				output &= bit_pack_container == shrunk_container
				output &= eltype(bit_pack) == Pair{
					keytype(shrunk), valtype(shrunk)
					}

				output &=
					hash(keys_iterator) == hash(shrunk_keys)
				output &=
					hash(reverse_keys) == hash(reverse_shrunk_keys)
				output &=
					hash(values_iterator) == hash(shrunk_values)
				output &=
					hash(reverse_values) == hash(reverse_shrunk_values)
				output &=
					hash(bit_pack) == hash(shrunk)
				output &=
					hash(reverse_bit_pack) == hash(reverse_shrunk)
				output &=
					hash(bit_pack_container) == hash(shrunk_container)

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
			via_index = copy(bit_pack)
			via_property = copy(bit_pack)

			output = all(
				x -> getproperty(bit_pack, first(x)) == bit_pack[last(x)],
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
		if consumed_capacity(bit_pack) > 0x8
			@test begin
				bit_flip = copy(bit_pack)
				bit_flip.bits = xor(
					one(bit_flip.bits), bit_flip.bits & one(bit_flip.bits)
					)
				bit_pack != bit_flip
			end
			@test_throws ArgumentError begin
				PackedInstances(UInt8, content...)
			end
			@test_throws ArgumentError begin
				vacant = PackedInstances(UInt8)
				PackedInstances(vacant, content...)
			end
			@test_throws ArgumentError begin
				PackedInstances(UInt8, bit_pack)
			end
		end

		# Augment with additional content if possible.
		if !isempty(leftover_types)
			@test begin
				consumed = consumed_capacity(bit_pack)
				new_type = rand(leftover_types)
				new_value = rand(instances(new_type))
				augmented = PackedInstances(bit_pack, new_value)
				consumed_capacity(augmented) ==
					consumed + encoding_bits(new_type)
			end

			# This displays an error message in the logs, perfectly benign.
			@test_throws KeyError begin
				new_type = rand(leftover_types)
				new_value = rand(instances(new_type))
				@info "The following error message is intentional."
				bit_pack[new_type] = new_value
			end
		end

		# Joint iterator correctness.
		@test begin
			# Choose between iterating forwards or backwards.
			direction = rand(Bool) ? identity : Iterators.reverse
			keys_itr = direction(keys_iterator)
			values_itr = direction(values_iterator)
			pairs_itr = direction(pairs(bit_pack))
			output = eltype(pairs_itr) == Pair{
				eltype(keys_itr),
				eltype(values_itr)
				}
			output &= eltype(bit_pack) == eltype(pairs_itr)
			for (key, value, key_value) in zip(keys_itr, values_itr, pairs_itr)
				output &= key == first(key_value) && value == last(key_value)
				output &= match_value(bit_pack, value)
			end
			output
		end

		# Always handled properly, be it naughty or nice.
		if rand(Bool)
			@test begin
				new_type = rand(types_to_avoid)
				output = !is_encodable(new_type)
				output &= !can_encode(bit_pack, new_type)
				output &= ismissing(encoding_bits(new_type))
			end

			@test_throws KeyError begin
				new_type = rand(types_to_avoid)
				bit_pack[new_type]
			end
		else
			@test begin
				new_type = rand(types_to_sample)
				output = is_encodable(new_type)
				output &= can_encode(bit_pack, new_type)
				output &= !ismissing(encoding_bits(new_type))
			end
		end

	end

end

#==============================================================================#
