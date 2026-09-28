
#==============================================================================#

function test_show(
	::Type{U},
	round_count::Integer,
	constructors::Base.AbstractVecOrTuple{Base.Callable},
	types_to_sample::Base.AbstractVecOrTuple{DataType}
	) where {U <: Unsigned}

	#===========================================================================
	PREDICATES
	===========================================================================#

	function content_predicate(
		input::Tuple{
			Tuple{AbstractString, BitPackedInstancesTypes},
			IOContext,
			Integer
			}
		)

		(source, iterator), io, count = input
		iterator = Iterators.take(iterator, count)
		representations = (repr(x; context = io) for x in iterator)
		return all(occursin(source), representations)

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

	# Induce all potential execution paths.
	minimum_count = 0x8
	padding_width = textwidth(string('\n', rpad("", 0x2)))
	height_threshold = 0x4
	height_offset = 0x3
	width_offset_iterators = padding_width << 0x1
	width_offset_bit_pack = width_offset_iterators + textwidth(" => ")
	display_range = (Base.OneTo(0x4) .+ 0x4, Base.OneTo(0x4) .+ 0xf)
	# The height is degenerate half the time whereas the width is always so.
	degenerate_range = (Base.OneTo(0x8), Base.OneTo(0xf))
	mime_type = MIME("text/plain")

	for round_number in Base.OneTo(round_count)

		if iseven(round_number)
			# Random length sequence of randomly selected types.
			selected = first(randperm(type_count), rand(interval))
		else
			# Encode as much as possible.
			selected = randperm(type_count)
		end
		@inbounds selected_types = types_to_sample[selected]
		selected_types = capacity_filter(U, selected_types)
		selected_count = length(selected_types)

		# Random supported constructor.
		constructor = rand(constructors)
		# Sets the reference for further tests.
		content = (rand(unique_instances(x)) for x in selected_types)
		bit_pack = constructor(U, content...)
		keys_iterator = keys(bit_pack)
		values_iterator = values(bit_pack)
		collection = (bit_pack, keys_iterator, values_iterator)
		iterators = (values_iterator, keys_iterator, values_iterator)

		# CAUTION: The displaysize MUST be provided as Tuple{Int, Int}.
		# Randomly sized dimensions, alongside different display modes.
		height, width = rand.(display_range)
		io = IOContext(stdout, :displaysize => Int.((height, width)))
		unlimited_io = IOContext(io, :compact => false, :limit => false)
		limited_io = IOContext(io, :compact => false, :limit => true)
		compact_io = IOContext(io, :compact => true)
		# Simulate pathological configurations.
		degenerate_height, degenerate_width = rand.(degenerate_range)
		degenerate_io = IOContext(
			stdout, :compact => false, :limit => true,
			:displaysize => Int.((degenerate_height, degenerate_width))
			)

		# MIME-less, limited.
		@test begin
			collection_repr = map(
				x -> repr(x; context = limited_io), collection
				)

			# CAUTION: Wrap single elements before passing.
			output = all(
				content_predicate,
				Iterators.product(
					zip(collection_repr, iterators),
					(limited_io,), (minimum_count >> 0x1,)
					)
				)
			if selected_count <= minimum_count
				output &= all(!contains('…'), collection_repr)
			else
				output &= all(contains('…'), collection_repr)
			end
			output
		end

		# MIME-less, unlimited.
		@test begin
			collection_repr = map(
				x -> repr(x; context = unlimited_io), collection
				)

			# CAUTION: Wrap single elements before passing.
			output = all(
				content_predicate,
				Iterators.product(
					zip(collection_repr, iterators),
					(unlimited_io,), (selected_count,)
					)
				)
			output &= all(!contains('…'), collection_repr)
		end

		isempty(bit_pack) && continue

		# MIME, compact.
		@test begin
			collection_repr = (
				repr(mime_type, x; context = compact_io) for x in collection
				)

			all(endswith('.'), collection_repr)
		end

		# MIME, degenerate.
		@test begin
			collection_repr = map(
				x -> repr(mime_type, x; context = degenerate_io), collection
				)

			if height_threshold < degenerate_height
				output = all(endswith('⋮'), collection_repr) && all(
					ComposedFunction(isone, Base.Fix{1}(count, '\n')),
					collection_repr
					)
			else
				output = all(endswith(": …"), collection_repr)
			end
			output
		end

		# MIME, limited.
		@test begin
			collection_repr = map(
				x -> repr(mime_type, x; context = limited_io), collection
				)
			# Skip the headline.
			collection_lines =
				@. Iterators.drop(
					eachline(IOBuffer(collection_repr)), one(selected_count)
					)
			width_limit_iterator = width - width_offset_iterators
			width_limit_bit_pack = (width - width_offset_bit_pack) >> 0x1

			output = count("=>", first(collection_repr)) == min(
				selected_count, height - height_offset
				)
			output &= all(contains(':'), collection_repr)

			for ((key, value), bit_pack_line, key_line, value_line) in zip(
				bit_pack, collection_lines...
				)

				key_string = repr(key; context = limited_io)
				value_string = repr(value; context = limited_io)
				key_width = textwidth(key_string)
				value_width = textwidth(value_string)
				if contains(bit_pack_line, '…')
					output &= width_limit_bit_pack < max(key_width, value_width)
				end
				if endswith(key_line, '…')
					output &= width_limit_iterator < key_width
				end
				if endswith(value_line, '…')
					output &= width_limit_iterator < value_width
				end

			end

			output
		end

		# MIME, unlimited.
		@test begin
			collection_repr = map(
				x -> repr(mime_type, x; context = unlimited_io), collection
				)
			bit_pack_repr = first(collection_repr)

			# CAUTION: Wrap single elements before passing.
			output = all(
				content_predicate,
				Iterators.product(
					zip(collection_repr, iterators),
					(unlimited_io,), (selected_count,)
					)
				)
			output &= all(contains(':'), collection_repr)
			output &= all(!contains('…'), collection_repr)
			output &= all(!endswith('⋮'), collection_repr)

			# CAUTION: Wrap single elements before passing.
			output &= all(
				content_predicate,
				Iterators.product(
					zip((bit_pack_repr,), (keys_iterator,)),
					(unlimited_io,), (selected_count,)
					)
				)
			output &= count("=>", bit_pack_repr) == selected_count
		end

	end

	return nothing

end

#==============================================================================#
