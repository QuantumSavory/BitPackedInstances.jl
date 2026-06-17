
#==============================================================================#

# Figure out the parameters of the arithmetic progression, if it is possible.
# CAUTION: The provided type must not be a singleton.
function check_arithmetic_progression(
	X::Type
	)

	# Sentinel output configuration.
	output = (
		validity = false,
		common_type = Integer,
		offset = 0x0,
		stride = 0x1
		)

	try
		values = instances(X)

		# Can potentially throw during casting to integral type or promotion.
		S = promote_type(map(x -> typeof(Integer(x)), values)...)
		# Can potentially throw during casting to this specific type.
		integral_values = (S(x) for x in values)
		# Can potentially throw during casting back.
		all(
			x -> first(x) == X(last(x)), zip(values, integral_values)
			) || return output

		# Proper validation is incredibly complicated, simply test as is.
		count = length(integral_values)
		count -= one(count)
		upper = Iterators.drop(integral_values, one(count))
		lower = Iterators.take(integral_values, count)
		differences = (splat(-)(x) for x in zip(upper, lower))

		# TODO: There has to be a cleaner way to achieve this.
		U = typeof(Unsigned(zero(S)))
		offset = reinterpret(U, first(integral_values))
		stride = reinterpret(U, first(differences))

		# Validity entails that there should be no rollover.
		shifted_values = (reinterpret(U, x) - offset for x in integral_values)

		output = ifelse(
			allequal(differences) && issorted(shifted_values),
			(
				validity = true,
				common_type = S,
				offset = offset,
				stride = stride
			),
			output
			)
	catch
		# Nothing need be done here.
	end

	return output

end

#==============================================================================#
