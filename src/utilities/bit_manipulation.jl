
#==============================================================================#

# CAUTION: Utilising sizeof is prone to error in the presence of metadata.
@inline function bit_count(
	::Type{U}
	) where {U <: Unsigned}

	return convert(U, count_zeros(zero(U)))

end

# Specifies number of bits necessary to encode this many configurations.
@inline function required_bits(
	configuration_count::U
	) where {U <: Unsigned}

	configuration_count = max(configuration_count, one(U))
	return bit_count(U) - convert(
		U, leading_zeros(configuration_count - one(U))
		)

end

# Quality of life shorthand.
@inline function required_bits(
	X::Type
	)

	return required_bits(convert(Unsigned, length(instances(X))))

end

# First set bit is at shifted position, total count up to span.
@inline function mask_bit_range(
	::Type{U}, span::Unsigned, shift::Unsigned
	) where {U <: Unsigned}

	return ~(~zero(U) << span) << shift

end

# CAUTION: Required bits must not exceed those available in the provided type.
@inline @generated function bits_from_value(
	::Type{U}, value::X, ::Val{shift}
	) where {U <: Unsigned, X, shift}

	if iszero(required_bits(X))
		output = quote
			return zero(U)
			end
	else
		progression = check_arithmetic_progression(X)
		if progression.validity
			common_type = progression.common_type
			# TODO: There has to be a cleaner way to achieve this.
			unsigned_type = typeof(Unsigned(zero(common_type)))
			offset = progression.offset
			stride = progression.stride
			# No need to worry about rounding due to integral ratio.
			output = quote
				return convert(
					U,
					div(reinterpret($unsigned_type, value) - $offset, $stride)
					) << $shift
				end
		else
			# CAUTION: Explicit construction rather than quotation, painful.
			conditional_tree = :(;;)
			current_branch = :(;;)
			for (counter, instance) in enumerate(instances(X))
				instance_bits = convert(U, counter - one(counter)) << shift
				clause = Expr(:call, :(==), :value, instance)
				body = Expr(:(=), :bits, instance_bits)
				if isone(counter)
					conditional_tree = Expr(:if, clause, body)
					current_branch = conditional_tree
				else
					new_branch = Expr(:elseif, clause, body)
					push!(current_branch.args, new_branch)
					current_branch = new_branch
				end
			end

			output = quote
				$conditional_tree
				return bits
				end
		end
	end

	return output

end

# CAUTION: Required bits must not exceed those available in the provided type.
@inline @generated function value_from_bits(
	::Type{X}, bits::U, ::Val{shift}, ::Val{skip_mask}
	) where {X, U <: Unsigned, shift, skip_mask}

	span = required_bits(X)
	if iszero(span)
		singleton = first(instances(X))
		output = quote
			return $singleton
			end
	else
		mask = mask_bit_range(U, span, zero(U))
		#======================================================================
		# TODO: Figure out how to enforce this optimisation.
		mask = ifelse(
			skip_mask,
			~zero(U),
			mask_bit_range(U, span, zero(U))
			)
		======================================================================#

		progression = check_arithmetic_progression(X)
		if progression.validity
			common_type = progression.common_type
			# TODO: There has to be a cleaner way to achieve this.
			unsigned_type = typeof(Unsigned(zero(common_type)))
			offset = progression.offset
			stride = progression.stride
			output = quote
				temp = convert($unsigned_type, (bits >> $shift) & $mask)
				return X($offset + $stride * reinterpret($common_type, temp))
				end
		else
			output = quote
				index = convert(Csize_t, (bits >> $shift) & $mask)
				@inbounds return instances(X)[index + one(index)]
				end
		end
	end

	return output

end

#==============================================================================#
