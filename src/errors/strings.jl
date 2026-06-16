
#==============================================================================#

function error_string_construction(
	::Type{U}
	) where {U <: Unsigned}

	available_bits = bit_count(U)
	# This is silly but no edge case shall be left unaccounted for.
	singular_or_plural = ifelse(isone(available_bits), "bit", "bits")

	output =
		"PackedInstances is unable to utilise the unsigned type ($U) since \
		encoding the provided argument(s) would exceed the available capacity \
		of ($available_bits) $singular_or_plural. Consider employing a larger \
		unsigned type for encoding the content."

	return output

end

function error_string_expansion(
	::Type{U}, ::Type{T}
	) where {U <: Unsigned, T <: Tuple}

	available_bits = bit_count(U) - convert(
		U, sum((required_bits(x) for x in fieldtypes(T)); init = zero(U))
		)
	# This is silly but no edge case shall be left unaccounted for.
	singular_or_plural = ifelse(isone(available_bits), "bit", "bits")

	output =
		"PackedInstances is unable to insert the newly provided argument(s) \
		as the encoding would require exceeding the remaining available \
		capacity of ($available_bits) $singular_or_plural. Consider employing \
		a larger unsigned type for encoding the content."

	return output

end

function error_string_conversion(
	::Type{U_new}, ::Type{U}, ::Type{T}
	) where {U_new <: Unsigned, U <: Unsigned, T <: Tuple}

	available_bits = bit_count(U_new)
	consumed_bits = convert(
		U, sum((required_bits(x) for x in fieldtypes(T)); init = zero(U))
		)
	# This is silly but no edge case shall be left unaccounted for.
	available_singular_or_plural = ifelse(
		isone(available_bits), "bit", "bits"
		)
	consumed_singular_or_plural = ifelse(
		isone(consumed_bits), "bit", "bits"
		)

	output =
		"PackedInstances is unable to utilise the unsigned type ($U_new) in \
		lieu of ($U) since encoding the existing content requires consuming \
		($consumed_bits) $consumed_singular_or_plural which would exceed the \
		new capacity of ($available_bits) $available_singular_or_plural. \
		Consider employing a larger unsigned type for encoding the content."

	return output

end

function error_string_insertion()

	output =
		"PackedInstances is unable to support the conventional dictionary \
		syntax for inserting new values. Consider modifying the expression to \
		instead become `bit_pack = PackedInstances(bit_pack, values...)`."

	return output

end

#==============================================================================#
