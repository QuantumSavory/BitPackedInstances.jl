
# Changelog

The format of this file is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and `BitPackedInstances` adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) in tagging its releases.

## [Unreleased]

## [0.3.1] - 2026-09-28

### Changed
- Enhance arithmetic progression encoding and retrieval for improved leniency.
- Optimise retrieval of arithmetic progressions via `@llvm.assume` range hints.

## [0.3.0] - 2026-09-27

### Added
- Introduce `AbstractPackedInstances` in order to unify the package interface.
- Extend method coverage for `ImmutablePackedInstances`.

### Changed
- Modify [`README.md`](README.md) to clarify optimal encoding conditions.
- Modify documentation to better reflect proper operation guidelines.
- Modify equality condition to require matching encoding types.
- Overhaul API, including structure and method nomenclature.
- Optimise retrieval for the final encoded (non-singleton) type.
- Optimise on-site function inlining.

### Fixed
- Rectify non-compliant function signatures for querying `eltype`, `keytype`, and `valtype`.
- Rectify incorrectly typed output for `AbstractPackedInstances` (reverse) iteration.
- Rectify encoding issue for signed arithmetic progressions.
- Rectify issue with `PackedInstancesValuesIterator` not updating alongside its `AbstractPackedInstances`.
- Rectify issue with `show` methods improperly handling IO properties.

## [0.2.0] - 2026-06-17

### Added
- Extend method coverage for reversed iterators.

### Changed
- Modify property name querying to properly delineate private content.
- Correct [`README.md`](README.md) for enhanced clarity and to note particular performance advice.
- Modify [`CHANGELOG.md`](CHANGELOG.md) to conform with [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) guidelines.

### Fixed
- Rectify encoding issue for types with numerous integer valued instances.
- Rectify non-compliant function signature for querying property names.
- Rectify equivalence issue when hashing key iterator inputs.

## [0.1.0] - 2026-05-30
Initial release of `BitPackedInstances`.

[Unreleased]: https://github.com/QuantumSavory/BitPackedInstances.jl/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/QuantumSavory/BitPackedInstances.jl/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/QuantumSavory/BitPackedInstances.jl/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/QuantumSavory/BitPackedInstances.jl/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/QuantumSavory/BitPackedInstances.jl/releases/tag/v0.1.0
