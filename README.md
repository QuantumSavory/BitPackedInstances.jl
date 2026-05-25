
# BitPackedInstances.jl

[![Build Status](https://github.com/QuantumSavory/BitPackedInstances.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/QuantumSavory/BitPackedInstances.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/QuantumSavory/BitPackedInstances.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/QuantumSavory/BitPackedInstances.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)

BitPackedInstances is lightweight package that facilitates the bit packing of any data types that support the `instances` querying interface via compact and efficient `@generated` implementations. The provided experience largely resembles that of a typical dictionary to the extent permissible by the prolific abuse of the `Julia` type system that is required in order to achieve the desired functionality.


# WARNING

- This package was developed with the primary objective of reducing the register pressure required to handle `@enum` parameters controlling tunable functionality. As such, the intended use case favours encoding statically known types rather than being a general purposes data structure.

- Due to thoroughly employing a large swathe of `@generated` function invocations, world age restrictions are of particular importance. To wit, any content which one wishes to have `PackedInstances` encode must be completely defined before `BitPackedInstances.jl` is imported into the parent scope.

# Exemplary usage

```julia
# MUST precede importing `BitPackedInstances`.
@enum Season begin winter; spring; summer; autumn; end
@enum Weather begin snowy; windy; sunny; rainy; end
@enum Mood begin pessimistic; optimistic; end

using BitPackedInstances

# Construct by passing an unsigned type and any number of values.
bit_pack = PackedInstances(UInt, snowy)
# Preferred content matching style.
@assert match_value(bit_pack, snowy)
# Regular retrieval is also possible in two distinct styles.
@assert bit_pack.Weather == bit_pack[Weather]
# Alter the underlying type.
bit_pack = PackedInstances(UInt8, bit_pack)
@assert encoding_type(bit_pack) == UInt8
# Overwrite existing fields
bit_pack.Weather = rainy
@assert match_value(bit_pack, rainy)
# Extend with new content.
bit_pack = PackedInstances(bit_pack, summer)
@assert match_value(bit_pack, summer)
# Both at once if so desired.
bit_pack = PackedInstances(bit_pack, sunny, optimistic)
@assert match_value(bit_pack, summer)
@assert match_value(bit_pack, sunny)
@assert match_value(bit_pack, optimistic)
# Eliminate what is no longer needed.
bit_pack = discard(bit_pack, Mood)
@assert !(haskey(bit_pack, Mood))
# Wrap it up and pass it through to JuliaGPU kernels.
@assert bit_pack == unwrap(wrap(bit_pack))

# World age forbids certain possibilities.
@enum Catastrophy begin impossible; end
# Failure awaits whoever attempts.
try
    bit_pack(UInt, impossible)
catch error
    @assert error isa MethodError
end
```
