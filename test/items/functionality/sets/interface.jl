
#==============================================================================#

function test_interface(
	::Type{U},
	round_count::Integer,
	constructors::Base.AbstractVecOrTuple{Base.Callable},
	types_to_sample::Base.AbstractVecOrTuple{DataType},
	types_to_avoid::Base.AbstractVecOrTuple{DataType}
	) where {U <: Unsigned}

	#===========================================================================
	PREDICATES
	===========================================================================#

	function overwrite_predicate(
		input::Tuple{
			Pair{DataType, <: Any},
			AbstractPackedInstances,
			Base.AbstractVecOrTuple{DataType},
			Any
			}
		)

		(key, value), modified, overwritten_types, new_content = input
		if !(key in overwritten_types)
			output = modified[key] == value
		else
			@inbounds new_value =
				new_content[findfirst(==(key), overwritten_types)]
			output = modified[key] == new_value
		end
		return output

	end

	function discard_predicate(
		input::Tuple{
			Pair{DataType, <: Any},
			Tuple{
				AbstractPackedInstances,
				Base.AbstractVecOrTuple{DataType}
				}
			}
		)

		(key, value), (partial, discarded_types) = input
		if !(key in discarded_types)
			output = partial[key] == value
		else
			output = !haskey(partial, key)
		end
		return output

	end

	#===========================================================================
	EVALUATION
	===========================================================================#

	# Required to be a positive value.
	round_count = max(round_count, one(round_count))

	# Only retain what may ever possibly be encoded.
	types_to_sample = can_encode_filter(U, types_to_sample)

	# Utilised extensively throughout.
	type_count = length(types_to_sample)
	interval = Base.OneTo(type_count)

	for _ in Base.OneTo(round_count)

		# Random length sequence of randomly selected types.
		leftover, selected = Base.split_rest(
			randperm(type_count), rand(interval)
			)
		@inbounds selected_types = types_to_sample[selected]
		@inbounds leftover_types = types_to_sample[leftover]
		selected_types = capacity_filter(U, selected_types)
		selected_singletons = Iterators.filter(
			ComposedFunction(
				ComposedFunction(isone, length),
				unique_instances
				),
			selected_types
			)
		selected_count = length(selected_types)

		# Random supported constructor.
		constructor = rand(constructors)
		# Sets the reference for further tests.
		content = map(
			ComposedFunction(rand, unique_instances), selected_types
			)
		bit_pack = constructor(U, content...)
		reverse_bit_pack = Iterators.reverse(bit_pack)
		keys_iterator = keys(bit_pack)
		reverse_keys = Iterators.reverse(keys_iterator)
		values_iterator = values(bit_pack)
		reverse_values = Iterators.reverse(values_iterator)
		collection = (
			bit_pack, reverse_bit_pack,
			keys_iterator, reverse_keys,
			values_iterator, reverse_values
			)

		# Standard routines.
		@test begin
			new_type = rand(types_to_avoid)

			output = eltype(bit_pack) == Pair{
				eltype(selected_types), eltype(content)
				}
			output &=
				eltype(selected_types) ==
					keytype(bit_pack)
						eltype(keys_iterator)
			output &=
				eltype(content) ==
					valtype(bit_pack) ==
						eltype(values_iterator)

			output &= bit_pack == pairs(bit_pack)
			output &= keys_iterator == eachindex(bit_pack)
			output &= all(
				x -> Set(first(x)) == Set(last(x)),
				(
					(selected_types, keys_iterator),
					(content, values_iterator)
					)
				)

			output &= length(selected_types) == length(keys_iterator)
			output &= length(content) == length(values_iterator)
			output &= allequal(length, collection)

			output &= all(Base.Fix{1}(haskey, bit_pack), selected_types)
			output &= all(!Base.Fix{1}(haskey, bit_pack), leftover_types)
			output &= first(content) == get(
				identity, bit_pack, first(selected_types)
				)
			output &= get(bit_pack, new_type, true)
			output &= getkey(bit_pack, new_type, true)

			output &= all(x -> x == copy(x), collection)
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
				output &= Pair(key, value) == key_value
				output &= match_content(bit_pack, value)
			end

			output &= match_content(bit_pack, values_itr...)
		end

		# Correct for both trivial and redundant conditions.
		@test begin
			match_content(bit_pack) ==
				match_content(
					bit_pack, values_iterator..., values_iterator...
					) == true
		end

		# Permutation invariance.
		@test begin
			@inbounds permuted = constructor(
				U, content[randperm(selected_count)]...
				)
			reverse_permuted = Iterators.reverse(permuted)
			permuted_keys = keys(permuted)
			reverse_permuted_keys = Iterators.reverse(permuted_keys)
			permuted_values = values(permuted)
			reverse_permuted_values = Iterators.reverse(permuted_values)
			permuted_collection = (
				permuted, reverse_permuted,
				permuted_keys, reverse_permuted_keys,
				permuted_values, reverse_permuted_values
				)

			output = eltype(bit_pack) == Pair{
				keytype(permuted), valtype(permuted)
				}

			output &= all(splat(==), zip(collection, permuted_collection))
			output &= all(
				x -> hash(first(x)) == hash(last(x)),
				zip(collection, permuted_collection)
				)
		end

		# Mechanism invariance.
		@test begin
			new_content = map(
				ComposedFunction(rand, unique_instances), selected_types
				)
			via_index = MutablePackedInstances(bit_pack)
			via_property = MutablePackedInstances(bit_pack)
			via_method = MutablePackedInstances(bit_pack)
			via_bulk = MutablePackedInstances(bit_pack)
			property_names = (Symbol(x) for x in selected_types)

			for (property_name, key, value) in zip(
				property_names, selected_types, new_content
				)

				via_index[key] = value
				setproperty!(via_property, property_name, value)
				overwrite!(via_method, value)

			end
			overwrite!(via_bulk, new_content...)

			output = via_index == via_property == via_method == via_bulk

			output &= Set(propertynames(bit_pack)) == Set(property_names)
			output &= all(
				ComposedFunction(isempty, propertynames),
				(keys_iterator, values_iterator)
				)

			output &= all(
				x -> getproperty(bit_pack, first(x)) == bit_pack[last(x)],
				zip(property_names, selected_types)
				)
		end

		# Partial type invariance.
		@test begin
			consumed = consumed_capacity(bit_pack)
			available = available_capacity(bit_pack)

			output = U == encoding_type(bit_pack)
			output &=
				available_capacity(constructor(U)) == consumed + available

			if consumed <= 0x10
				shrunk = AbstractPackedInstances(UInt16, bit_pack)
				reverse_shrunk = Iterators.reverse(shrunk)
				shrunk_keys = keys(shrunk)
				reverse_shrunk_keys = Iterators.reverse(shrunk_keys)
				shrunk_values = values(shrunk)
				reverse_shrunk_values = Iterators.reverse(shrunk_values)
				shrunk_collection = (
					shrunk, reverse_shrunk,
					shrunk_keys, reverse_shrunk_keys,
					shrunk_values, reverse_shrunk_values
					)

				# `Base.split_rest` demands an `Int` argument.
				bit_packs, iterators = Base.split_rest(collection, 4)
				shrunk_bit_packs, shrunk_iterators = Base.split_rest(
					shrunk_collection, 4
					)

				output &= UInt16 == encoding_type(shrunk)
				output &=
					0x10 ==
						consumed_capacity(shrunk) + available_capacity(shrunk)

				output &= eltype(bit_pack) == Pair{
					keytype(shrunk), valtype(shrunk)
					}

				output &= all(splat(!=), zip(bit_packs, shrunk_bit_packs))
				output &= all(splat(==), zip(iterators, shrunk_iterators))
				output &= all(
					x -> all(splat(==), zip(x...)),
					zip(collection, shrunk_collection)
					)
			end

			output
		end

		# Either encode directly or start vacant and then augment.
		@test begin
			vacant = MutablePackedInstances(U)
			full = constructor(vacant, content...)
			vacant.bits |= one(vacant.bits)
			isone(vacant.bits) && bit_pack == full
		end

		# Either encode directly or encode partially and then augment.
		@test begin
			now, later = Base.split_rest(
				randperm(selected_count), rand(Base.OneTo(selected_count))
				)
			@inbounds partial = constructor(U, content[now]...)
			@inbounds complete =
				AbstractPackedInstances(partial, content[later]...)
			bit_pack == complete
		end

		# Overwrite some values.
		@test begin
			overwritten = first(
				randperm(selected_count), rand(Base.OneTo(selected_count))
				)
			@inbounds overwritten_types = selected_types[overwritten]
			new_content = map(
				ComposedFunction(rand, unique_instances), overwritten_types
				)

			bulk_modified = MutablePackedInstances(bit_pack)
			individually_modified = MutablePackedInstances(bit_pack)
			for (key, value) in zip(overwritten_types, new_content)
				individually_modified[key] = value
			end
			overwrite!(bulk_modified, new_content...)

			output = bulk_modified == individually_modified
			# CAUTION: Wrap single elements before passing.
			output &= all(
				overwrite_predicate,
				Iterators.product(
					bit_pack, (bulk_modified,),
					(overwritten_types,), (new_content,)
					)
				)
		end

		# Discard various segments.
		@test begin
			@inbounds front_segment = selected_types[
				begin : max(begin, end >> 0x1)
				]
			back_segment = filter(!in(front_segment), selected_types)
			@inbounds inner_segment = selected_types[
				max(begin, end >> 0x2) : max(begin, end >> 0x1)
				]
			outer_segment = filter(!in(inner_segment), selected_types)
			segments = (
				front_segment, back_segment,
				inner_segment, outer_segment
				)

			front_bit_pack = discard(bit_pack, front_segment...)
			back_bit_pack = discard(bit_pack, back_segment...)
			inner_bit_pack = discard(bit_pack, inner_segment...)
			outer_bit_pack = discard(bit_pack, outer_segment...)
			partial_collection = (
				front_bit_pack, back_bit_pack,
				inner_bit_pack, outer_bit_pack
			)

			output = all(
				ComposedFunction(<=(selected_count), length),
				partial_collection
				)
			output &= all(
				discard_predicate,
				Iterators.product(
					bit_pack, zip(partial_collection, segments)
					)
				)

			output &= bit_pack == discard(bit_pack, leftover_types...)
			output &= isempty(discard(bit_pack, selected_types...))
			output &=
				bit_pack.bits == discard(bit_pack, selected_singletons...).bits
		end

		# Potential accidents that may transpire.
		if 0x8 < consumed_capacity(bit_pack)
			@test begin
				bit_flip = MutablePackedInstances(bit_pack)
				bit_flip.bits = xor(
					one(bit_flip.bits),
					bit_flip.bits & one(bit_flip.bits)
					)
				bit_pack != constructor(bit_flip)
			end

			@test_throws ArgumentError begin
				constructor(UInt8, content...)
			end
			@test_throws ArgumentError begin
				vacant = constructor(UInt8)
				AbstractPackedInstances(vacant, content...)
			end
			@test_throws ArgumentError begin
				AbstractPackedInstances(UInt8, bit_pack)
			end
		end

		if !isempty(leftover_types)
			# Augment with additional content if possible.
			@test begin
				new_type = rand(leftover_types)
				output = true
				if can_encode(bit_pack, new_type)
					new_value = rand(unique_instances(new_type))
					consumed = consumed_capacity(bit_pack)
					augmented = AbstractPackedInstances(bit_pack, new_value)
					output = consumed_capacity(augmented) ==
						consumed + encoding_bits(new_type)
				end
				output
			end

			# Absent types and their corresponding keys.
			@test_throws KeyError begin
				new_type = rand(leftover_types)
				new_value = rand(unique_instances(new_type))
				target = MutablePackedInstances(bit_pack)
				# This would display an error message, suppress it.
				@suppress_err target[new_type] = new_value
			end
			@test_throws KeyError begin
				new_value = rand(unique_instances(rand(leftover_types)))
				target = MutablePackedInstances(bit_pack)
				overwrite!(target, new_value)
			end
			@test_throws KeyError begin
				new_value = rand(unique_instances(rand(leftover_types)))
				match_content(bit_pack, new_value)
			end
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
				new_type = rand(selected_types)
				output = is_encodable(new_type)
				output &= can_encode(bit_pack, new_type)
				output &= !ismissing(encoding_bits(new_type))
			end
		end

	end

	return nothing

end

#==============================================================================#
