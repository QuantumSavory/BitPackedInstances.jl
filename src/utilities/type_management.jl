
#==============================================================================#

# CAUTION: This is slightly unsafe due to potential hash clashes.
@inline function canonical_form(
	input::Tuple
	)

	return sort(input; by = hash)

end

# TODO: There has to be a built-in method that does this.
@inline function unwrap_type(
	::Type{Type{X}}
	) where {X}

	return X

end

#==============================================================================#
