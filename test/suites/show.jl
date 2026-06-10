
#==============================================================================#

function test_show(
	round_count::Unsigned,
	types_to_sample::Base.AbstractVecOrTuple
	)

	# Utilised extensively throughout.
	type_count = length(types_to_sample)
	interval = Base.OneTo(type_count)
	display_dimensions = displaysize(stdout)
	display_range = Base.OneTo.(display_dimensions)
	mime_type = MIME("text/plain")

	for round_number in Base.OneTo(round_count)

		if iseven(round_number)
			# Random length sequence of randomly selected types.
			selected = Base.first(randperm(type_count), rand(interval))
			@inbounds selected_types = types_to_sample[selected]
		else
			# Encode everything permissible.
			selected_types = types_to_sample
		end

		# Sets the baseline for further tests.
		content = map(x -> rand(instances(x)), selected_types)
		bit_pack = PackedInstances(UInt64, content...)
		bit_pack_container = wrap(bit_pack)
		keys_iterator = keys(bit_pack)
		values_iterator = values(bit_pack)
		collection =
			(bit_pack, bit_pack_container, keys_iterator, values_iterator)

		# Randomly sized dimensions, alongside different display modes.
		height, width = rand.(display_range)
		io = IOContext(stdout, :displaysize => (height, width))
		compact_io = IOContext(io, :compact => true)
		succinct_io = IOContext(io, :limited => true)
		nested_io = IOContext(io, :compact => true, :limited => true)

		# Compact, non-"text/plain".
		@test begin
			all(
				x ->
					length(repr(x; context = compact_io)) <=
						length(string(typeof(x))),
				collection
				)
		end

		# Non-compact, non-"text/plain".
		@test begin
			bit_pack_repr = repr(
				bit_pack; context = io
				)
			bit_pack_container_repr = repr(
				bit_pack_container; context = io
				)
			keys_iterator_repr = repr(
				keys_iterator; context = io
				)
			values_iterator_repr = repr(
				values_iterator; context = io
				)

			output = all(
				occursin(keys_iterator_repr),
				repr.(first(keys_iterator, 0x4); context = nested_io)
				)
			output &= all(
				occursin(values_iterator_repr),
				repr.(first(values_iterator, 0x4); context = nested_io)
				)
			output &= all(
				occursin(bit_pack_repr),
				repr.(first(values_iterator, 0x4); context = nested_io)
				)
			output &= all(
				occursin(bit_pack_container_repr),
				repr.(first(values_iterator, 0x4); context = nested_io)
				)
		end

		# Compact, "text/plain".
		@test begin
			collection_repr = map(
				x -> repr(mime_type, x; context = compact_io), collection
				)
			all(!contains(":\n"), collection_repr)
		end

		if length(bit_pack) > 0x8
			# Succinct, non-"text/plain".
			@test begin
				collection_repr = map(
					x -> repr(x; context = succinct_io), collection
					)
				all(contains("…"), collection_repr)
			end
		end

		if !isempty(bit_pack)
			# Succinct, "text/plain".
			@test begin
				collection_repr = map(
					x -> repr(mime_type, x; context = succinct_io), collection
					)

				output = all(contains(":\n"), collection_repr)
				if all(contains("⋮"), collection_repr)
					output &= width < 0x20 || length(bit_pack) > 0x8
				end
				output &= occursin("=>", first(collection_repr))
			end
		end

	end

end

#==============================================================================#
