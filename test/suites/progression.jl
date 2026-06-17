
#==============================================================================#

function test_progression(
	types_to_test::Base.AbstractVecOrTuple
	)

	for target_type in types_to_test

		content = instances(target_type)
		count = length(content)
		# Unlike indices, these start from zero.
		bit_patterns = zero(count) : (count - one(count))

		@test begin
			output = all(
				x -> match_value(PackedInstances(UInt, x), x),
				content
				)
			output &= all(
				x -> PackedInstances(UInt, first(x)).bits == last(x),
				zip(content, bit_patterns)
				)
		end

	end

end

#==============================================================================#
