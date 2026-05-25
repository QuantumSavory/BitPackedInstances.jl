
#==============================================================================#

# Figure out the parameters of the arithmetic progression, if it is possible.
# CAUTION: Always check the validity before proceeding.
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
		S = promote_type(typeof.(Integer.(values))...)
		# Can potentially throw during casting to this specific type.
		integral_values = S.(values)
		# Can potentially throw during casting back.
		values == X.(integral_values) || return output

		if isone(length(integral_values))
			# CAUTION: Singletons ought to be handled separately.
			output = (
				validity = true,
				common_type = S,
				offset = first(integral_values),
				stride = one(S)
				)
		else
			# CAUTION: Instances may have ordered values in disordered definition.
			integral_values = sort(integral_values)
			reverse_values = Iterators.reverse(integral_values)
			upper = Base.rest(integral_values, last(iterate(integral_values)))
			lower = Base.rest(reverse_values, last(iterate(reverse_values)))
			differences = upper .- lower
			output = ifelse(
				allequal(differences),
				(
					validity = true,
					common_type = S,
					offset = first(integral_values),
					stride = first(differences)
				),
				output
				)
		end
	catch
		# Nothing need be done here.
	end

	return output

end

#==============================================================================#
