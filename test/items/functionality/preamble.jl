
#==============================================================================#

#===============================================================================
CONFIGURATION
===============================================================================#

# Sufficiently thorough sampling.
const round_count = 0x40

# Sufficiently large as to encompass everything, sans generated enumerations.
const unsigned_type = UInt64

#===============================================================================
ENUMERATIONS
===============================================================================#

# Various types and number of instances.
@enum EnumA::Int8 begin a_1; a_2; end
@enum EnumB::UInt8 begin b_1; b_2; b_3; end
@enum EnumC::Int16 begin c_1; c_2; c_3; c_4; end
@enum EnumD::UInt16 begin d_1; d_2; d_3; d_4; d_5; end
@enum EnumE::Int32 begin e_1; e_2; e_3; e_4; e_5; e_6; end
@enum EnumF::UInt32 begin f_1; f_2; f_3; f_4; f_5; f_6; f_7; end

# Unordered, not an arithmetic progression, or both.
@enum Primes::Int64 begin
	seven = 7;
	three = 3;
	two = 2;
	five = 5;
	eleven = 11;
end
@enum Squares::UInt64 begin
	four = 4
	nine = 9
	sixteen = 16
	twenty_five = 25
	thirty_six = 36
end

# Consumes no bits to encode.
@enum SingletonA begin a_singleton; end
@enum SingletonB begin b_singleton; end
@enum SingletonC begin c_singleton; end
@enum SingletonD begin d_singleton; end

# Output display width handling.
@enum Hippopotomonstrosesquippedaliophobia begin
	short_value
end
@enum ShortKey begin
	pneumonoultramicroscopicsilicovolcanoconiosis
end

# Can potentially have an absurdly large instance count.
let

	# TODO: There has to be a cleaner way to achieve this.
	candidate_types = (
		Int8, UInt8,
		Int16, UInt16,
		Int32, UInt32,
		Int64, UInt64,
		Int128, UInt128
		)

	# Retain sane cutoff.
	maximum_instances = 0xff

	for enum_counter in Base.OneTo(round_count)
		value_type = rand(candidate_types)
		stride = zero(value_type)
		while stride < one(value_type)
			stride = rand(value_type)
		end

		instances = Expr[]
		sizehint!(instances, maximum_instances)
		counter = zero(maximum_instances)
		current = rand(value_type)
		next = current
		while current <= next && counter < maximum_instances
			push!(
				instances,
				Expr(
					:(=),
					Symbol("enum_", enum_counter, "_", counter),
					next
					)
				)
			current = next
			next += stride
			counter += one(counter)
		end

		enum_expression = Expr(
			:macrocall,
			Symbol("@enum"),
			# This is necessary for proper parsing.
			LineNumberNode(1),
			Expr(
				Symbol("::"),
				Symbol("Enum_", enum_counter),
				Symbol(value_type)
				),
			instances...
			)

		@eval $enum_expression
	end

end

#===============================================================================
CUSTOM
===============================================================================#

# Support should not be restricted to built-in types.
struct CustomInstances

	bits::UInt8

	_a_instance() = new(0x1)
	_b_instance() = new(0x2)
	_c_instance() = new(0x4)
	_d_instance() = new(0x8)

	global const a_instance = _a_instance()
	global const b_instance = _b_instance()
	global const c_instance = _c_instance()
	global const d_instance = _d_instance()

end

function Base.instances(::Type{CustomInstances})

	return (a_instance, b_instance, c_instance, d_instance)

end

# Arithmetic progressions come in all forms.
struct CustomProgression

	value::Integer

	_x_instance() = new(UInt8(1))
	_y_instance() = new(UInt16(2))
	_z_instance() = new(UInt32(3))
	_w_instance() = new(UInt64(4))

	global const x_instance = _x_instance()
	global const y_instance = _y_instance()
	global const z_instance = _z_instance()
	global const w_instance = _w_instance()

end

function Base.instances(::Type{CustomProgression})

	return (x_instance, y_instance, z_instance, w_instance)

end

function Base.Integer(
	input::CustomProgression
	)

	return input.value

end

function (::Type{S})(
	input::CustomProgression
	) where {S <: Integer}

	return S(input.value)

end

function CustomProgression(
	input::Integer
	)

	for element in instances(CustomProgression)
		input == Integer(element) && return element
	end
	throw(ArgumentError("Invalid CustomProgression value: $input"))

end

#===============================================================================
PACKAGES
===============================================================================#

# CAUTION: Ensure the encoded types are defined before importing.
using BitPackedInstances
using Random: randperm, randsubseq
using Suppressor: @suppress_err
using Test: @testset, @test, @test_throws

#===============================================================================
CONVENIENCE
===============================================================================#

@inline function can_encode_filter(
	::Type{U}, content_types::Base.AbstractVecOrTuple{DataType}
	) where {U <: Unsigned}

	vacant = ImmutablePackedInstances(U)
	output = filter(Base.Fix{1}(can_encode, vacant), content_types)
	isempty(output) && throw(ArgumentError("Invalid test suite initialisation"))
	return output

end

@inline function capacity_filter(
	::Type{U}, content_types::Base.AbstractVecOrTuple{DataType}
	) where {U <: Unsigned}

	content_types = can_encode_filter(U, content_types)
	capacity = BitPackedInstances.bit_count(U)
	consumed = accumulate(
		+, (encoding_bits(x) for x in content_types); init = zero(U)
		)
	@inbounds return content_types[findall(<=(capacity), consumed)]

end

@inline function unique_instances(
	X::Type
	)

	return BitPackedInstances.unique_instances(X)

end

const BitPackedInstancesTypes = Union{
	AbstractPackedInstances,
	BitPackedInstances.PackedInstancesKeysIterator,
	BitPackedInstances.PackedInstancesValuesIterator
	}

const AbstractPackedInstances_types = (
	MutablePackedInstances, ImmutablePackedInstances
	)

const benevolent_types = (
	EnumA, EnumB, EnumC, EnumD, EnumE, EnumF,
	Primes, Squares, CustomInstances, CustomProgression,
	SingletonA, SingletonB, SingletonC, SingletonD,
	Hippopotomonstrosesquippedaliophobia, ShortKey
	)

const malevolent_types = (
	Nothing, Bool, Expr, Symbol
	)

const generated_enums = tuple(
	(eval(Symbol("Enum_", x)) for x in Base.OneTo(round_count))...
	)

#===============================================================================
SETS
===============================================================================#

include("sets/interface.jl")
include("sets/progression.jl")
include("sets/show.jl")

#==============================================================================#
