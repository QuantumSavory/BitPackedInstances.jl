
#==============================================================================#

function test_progression(
	::Type{U},
	constructors::Base.AbstractVecOrTuple{Base.Callable},
	types_to_test::Base.AbstractVecOrTuple{DataType}
	) where {U <: Unsigned}

	# Only retain what may ever possibly be encoded.
	types_to_test = can_encode_filter(U, types_to_test)

	for target_type in types_to_test

		# Random supported constructor.
		constructor = rand(constructors)
		content = unique_instances(target_type)
		count = length(content)
		# Unlike indices, these start from zero.
		bit_patterns = zero(count) : (count - one(count))

		@test begin
			all(
				x -> match_content(constructor(U, x), x),
				content
				) && all(
					x -> constructor(U, first(x)).bits == last(x),
					zip(content, bit_patterns)
					)
		end

	end

	return nothing

end

#==============================================================================#
