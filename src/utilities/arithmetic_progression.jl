
#==============================================================================#

#===============================================================================
TRANSFORMATION
===============================================================================#

@inline function transformation_step(
	target::Type, value, ::Val{:identity}
	)

	return value

end

@inline function transformation_step(
	target::Type, value, ::Val{:reinterpret}
	)

	return reinterpret(target, value)

end

@inline function transformation_step(
	target::Type, value, ::Val{:convert}
	)

	return convert(target, value)

end

@inline function transformation_step(
	target::Type, value, ::Val{:construct}
	)

	return target(value)

end

#===============================================================================
VALIDATION
===============================================================================#

# Figure out the parameters of the arithmetic progression, if it is possible.
# This is marked as `@generated` in order to cache the output.
# CAUTION: The provided type must not be a singleton.
@generated function check_arithmetic_progression(
	X::Type
	)

	@inline function retrieval_predicate(
		input::Tuple{Base.Callable, Any, Integer}
		)

			from_integer_method, original, integral = input
			return original == from_integer_method(integral)

	end

	# Sentinel output configuration.
	# CAUTION: The common type is actually a value due to `isbits` requirement.
	output = (
		validity = false,
		steps = (
			to_integer = (:identity, :identity),
			from_integer = :identity
			),
		common_type = 0x0,
		offset = 0x0,
		stride = 0x1
		)

	# Eliminate Type{X} wrapper.
	X = unwrap_type(X)
	values = unique_instances(X)
	count = length(values)

	try

		steps = output.steps
		S = typeof(output.common_type)

		success_status = false
		for (to_integer) in (
			(:convert, :identity),
			(:construct, :identity)
			)

			method = Base.Fix{1}(
				Base.Fix{3}(
					transformation_step,
					Val(first(to_integer))
					),
				Integer
				)

			try
				# Can potentially throw during transformation or promotion.
				S = promote_type((typeof(method(x)) for x in values)...)
				success_status = true
				steps = (steps..., to_integer = to_integer)
				break
			catch
				# Nothing need be done here.
			end

		end
		success_status || throw()

		to_integer_method = identity

		success_status = false
		for (to_integer) in (
			(:identity, :reinterpret),
			(:identity, :convert),
			(:identity, :construct),
			(first(steps.to_integer), :reinterpret),
			(first(steps.to_integer), :convert)
			)


			method = ComposedFunction(
					Base.Fix{1}(
						Base.Fix{3}(
							transformation_step,
							Val(last(to_integer))
							),
						S
						),
					Base.Fix{1}(
						Base.Fix{3}(
							transformation_step,
							Val(first(to_integer))
							),
						Integer
						)
					)

			try
				# Can potentially throw during transformation to this type.
				success_status = allunique(method, values)
				if success_status
					steps = (steps..., to_integer = to_integer)
					to_integer_method = method
					break
				end
			catch
				# Nothing need be done here.
			end

		end
		success_status || throw()

		integer_values = (to_integer_method(x) for x in values)

		success_status = false
		for (from_integer) in (
			:reinterpret,
			:convert,
			:construct
			)

			method = Base.Fix{1}(
				Base.Fix{3}(
					transformation_step,
					Val(from_integer)
					),
				X
				)

			try
				# Can potentially throw during transformation from this type.
				success_status = all(
					retrieval_predicate,
					zip(
						Iterators.repeated(method, count),
						values,
						integer_values
						)
					)
				if success_status
					steps = (steps..., from_integer = from_integer)
					break
				end
			catch
				# Nothing need be done here.
			end

		end
		success_status || throw()

		# Proper validation is incredibly complicated, simply test as is.
		upper = Iterators.drop(integer_values, one(count))
		lower = Iterators.take(integer_values, count - one(count))
		differences = (splat(-)(x) for x in zip(upper, lower))

		U = unsigned(S)
		offset = reinterpret(U, first(integer_values))
		stride = reinterpret(U, first(differences))

		# Validity entails that there should be no wraparound.
		shifted_values = (reinterpret(U, x) - offset for x in integer_values)

		output = ifelse(
			allequal(differences) && issorted(shifted_values),
			(
				validity = true,
				steps = steps,
				common_type = zero(S),
				offset = offset,
				stride = stride
				),
			output
			)
	catch
		# Nothing need be done here.
	end

	return quote
		return $output
		end

end

#===============================================================================
INTERFACE
===============================================================================#

# CAUTION: Validity is assumed.
@inline function to_integer(
	::Type{U}, value::X, ::Val{progression}
	) where {U <: Unsigned, X, progression}

	to_integer = progression.steps.to_integer
	S = typeof(progression.common_type)
	unsigned_type = unsigned(S)
	offset = progression.offset
	stride = progression.stride
	# Enables optimiser to eliminate extraneous instruction.
	mask = convert(unsigned_type, ~zero(unsigned_type) & ~zero(U))

	@inline temp =
		transformation_step(Integer, value, Val(first(to_integer)))
	@inline unsigned_value = reinterpret(
		unsigned_type,
		transformation_step(S, temp, Val(last(to_integer)))
		)
	# No need to worry about rounding due to integral ratio.
	@inline return convert(
		U, div(unsigned_value - offset, stride) & mask
		)

end

# CAUTION: Validity is assumed.
@inline function from_integer(
	::Type{X}, bits::U, ::Val{incomplete_mask}, ::Val{progression}
	) where {X, U <: Unsigned, incomplete_mask, progression}

	to_integer = progression.steps.to_integer
	from_integer = progression.steps.from_integer
	S = typeof(progression.common_type)
	unsigned_type = unsigned(S)
	offset = progression.offset
	stride = progression.stride
	# Enables optimiser to eliminate extraneous instruction.
	mask = convert(U, ~zero(unsigned_type) & incomplete_mask)
	# Provides optimiser with a range hint.
	to_integer_method = ComposedFunction(
		Base.Fix{1}(
			Base.Fix{3}(
				transformation_step,
				Val(last(to_integer))
				),
			S
			),
		Base.Fix{1}(
			Base.Fix{3}(
				transformation_step,
				Val(first(to_integer))
				),
			Integer
			)
		)
	lower, upper = extrema(to_integer_method, unique_instances(X))

	@inline unsigned_value = muladd(
		convert(unsigned_type, bits & mask), stride, offset
		)
	@inline temp = reinterpret(S, unsigned_value)
	@inline assume(lower <= temp <= upper)
	@inline return transformation_step(X, temp, Val(from_integer))

end

#==============================================================================#
