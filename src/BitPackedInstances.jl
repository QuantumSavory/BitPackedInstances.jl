
#==============================================================================#

"""

`BitPackedInstances` is lightweight package that facilitates the bit packing of
any data types that support the `instances` querying interface via compact and
efficient `@generated` implementations.

"""
module BitPackedInstances

include("utilities.jl")
include("errors.jl")
include("structures.jl")
include("interface.jl")
include("output.jl")
include("exports.jl")

end

#==============================================================================#
