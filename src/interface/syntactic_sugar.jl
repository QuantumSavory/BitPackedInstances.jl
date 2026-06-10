
#==============================================================================#

#===============================================================================
INDEX
===============================================================================#

@inline @generated function Base.getindex(
	bit_pack::PackedInstances{U, T}, key::Type{X}
	) where {U <: Unsigned, T <: Tuple, X}

	content = fieldtypes(T)
	search_success = false
	shift = zero(U)

	for variety in content
		search_success = variety == X
		search_success && break
		shift += convert(U, required_bits(variety))
	end

	search_success || throw(KeyError(X))

	return quote
		return value_from_bits(X, bit_pack.bits, Val($shift))
		end

end

@inline @generated function Base.setindex!(
	bit_pack::PackedInstances{U, T}, value::X, key::Type{X}
	) where {U <: Unsigned, T <: Tuple, X}

	content = fieldtypes(T)
	search_success = false
	shift = zero(U)

	for variety in content
		search_success = variety == X
		search_success && break
		shift += convert(U, required_bits(variety))
	end

	if !search_success
		@error error_string_insertion()
		throw(KeyError(X))
	end

	if iszero(required_bits(X))
		output = quote
			return bit_pack
			end
	else
		mask = ~mask_bit_range(U, required_bits(X), shift)
		output = quote
			bit_pack.bits &= $mask
			bit_pack.bits |= bits_from_value(U, value, Val($shift))
			return bit_pack
			end
	end

	return output


end

#===============================================================================
INDIRECT
===============================================================================#

@inline function _indirect_getindex(
	bit_pack::PackedInstances{U, T}, ::Val{index}
	) where {U <: Unsigned, T <: Tuple, index}

	content = canonical_form(fieldtypes(T))
	index in eachindex(content) || throw(KeyError(Val(index)))
	@inbounds output = bit_pack[content[index]]
	return output

end

@inline function _indirect_setindex!(
	bit_pack::PackedInstances{U, T}, value, ::Val{index}
	) where {U <: Unsigned, T <: Tuple, index}

	content = canonical_form(fieldtypes(T))
	index in eachindex(content) || throw(KeyError(Val(index)))
	@inbounds bit_pack[content[index]] = value
	return value

end

#===============================================================================
PROPERTY
===============================================================================#

@inline function Base.propertynames(
	bit_pack::PackedInstances{U, T}, private::Bool = false
	) where {U <: Unsigned, T <: Tuple}

	content = Symbol.(canonical_form(fieldtypes(T)))
	private_content = fieldnames(PackedInstances)
	return ifelse(
		private,
		(content..., private_content...),
		content
		)

end

@generated function Base.getproperty(
	bit_pack::PackedInstances{U, T}, desired_property::Symbol
	) where {U <: Unsigned, T <: Tuple}

	content = canonical_form(fieldtypes(T))
	property_symbols = Symbol.(content)

	if isempty(property_symbols)
		# CAUTION: Handle separately due to clashing with tree construction.
		output = quote
			return getfield(bit_pack, desired_property)
			end
	else
		# CAUTION: Explicit construction rather than quotation, painful.
		conditional_tree = :(;;)
		current_branch = :(;;)
		index = firstindex(content)
		for (counter, property_symbol) in enumerate(property_symbols)
			node = QuoteNode(property_symbol)
			clause = Expr(:call, :(==), :desired_property, node)
			body = Expr(
				:(=),
				:output,
				Expr(:call, :_indirect_getindex, :bit_pack, Val(index))
				)

			if isone(counter)
				conditional_tree = Expr(:if, clause, body)
				current_branch = conditional_tree
			else
				new_branch = Expr(:elseif, clause, body)
				push!(current_branch.args, new_branch)
				current_branch = new_branch
			end

			index = nextind(content, index)
		end
		# The final clause, whatever does not match the above.
		push!(
			current_branch.args,
			Expr(
				:(=),
				:output,
				Expr(:call, :getfield, :bit_pack, :desired_property)
				)
			)

		output = quote
			$conditional_tree
			return output
			end
	end

	return output

end

@generated function Base.setproperty!(
	bit_pack::PackedInstances{U, T}, desired_property::Symbol, value
	) where {U <: Unsigned, T <: Tuple}

	content = canonical_form(fieldtypes(T))
	property_symbols = Symbol.(content)

	if isempty(property_symbols)
		# CAUTION: Handle separately due to clashing with tree construction.
		output = quote
			return setfield!(bit_pack, desired_property, value)
			end
	else
		# CAUTION: Explicit construction rather than quotation, painful.
		conditional_tree = :(;;)
		current_branch = :(;;)
		index = firstindex(content)
		for (counter, property_symbol) in enumerate(property_symbols)
			node = QuoteNode(property_symbol)
			clause = Expr(:call, :(==), :desired_property, node)
			body = Expr(
				:call, :_indirect_setindex!, :bit_pack, :value, Val(index)
				)

			if isone(counter)
				conditional_tree = Expr(:if, clause, body)
				current_branch = conditional_tree
			else
				new_branch = Expr(:elseif, clause, body)
				push!(current_branch.args, new_branch)
				current_branch = new_branch
			end

			index = nextind(content, index)
		end
		# The final clause, whatever does not match the above.
		push!(
			current_branch.args,
			Expr(:call, :setfield!, :bit_pack, :desired_property, :value)
			)

		output = quote
			$conditional_tree
			return value
			end
	end

	return output

end

#==============================================================================#
