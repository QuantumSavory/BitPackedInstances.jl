
#==============================================================================#

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
@enum EnumG::Int64 begin g_1; g_2; g_3; g_4; g_5; g_6; g_7; g_8; end

# Unordered, not an arithmetic progression.
@enum Primes::UInt64 begin
	seven = 7;
	three = 3;
	two = 2;
	five = 5;
	eleven = 11;
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
	value_type = rand((Int8, UInt8))
	stride = zero(value_type)
	while stride < one(value_type)
		stride = rand(value_type)
	end

	counter = 0x0
	current = rand(value_type)
	instances = [Expr(:(=), Symbol("absurd_", counter), current)]
	next = current + stride
	counter += one(counter)
	while next > current
		push!(instances, Expr(:(=), Symbol("absurd_", counter), next))
		current = next
		next += stride
		counter += one(counter)
	end

	enum_expression = Expr(
		:macrocall,
		Symbol("@enum"),
		# This is necessary for proper parsing.
		LineNumberNode(1),
		Expr(Symbol("::"), :Absurd, Symbol(value_type)),
		instances...
		)

	@eval $enum_expression
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

#===============================================================================
PACKAGES
===============================================================================#

# CAUTION: Ensure the encoded types are defined before importing.
using BitPackedInstances
using Test
using Random: randperm, randsubseq

#===============================================================================
CONFIGURATION
===============================================================================#

const benevolent_types = [
	EnumA, EnumB, EnumC, EnumD, EnumE, EnumF, EnumG, Primes,
	SingletonA, SingletonB, SingletonC, SingletonD,
	Hippopotomonstrosesquippedaliophobia, ShortKey, Absurd, CustomInstances
	]

const malevolent_types = [
	Nothing, Bool, Type, Symbol
	]

# Sufficiently thorough sampling.
const round_count = 0x40

#==============================================================================#
