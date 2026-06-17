
# Changelog

The format of this file is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and `BitPackedInstances` adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) in tagging its releases.

## [Unreleased]

### Changed
- Modify [`README.md`](README.md) to clarify optimal encoding conditions.
- Rectify non-compliant function signatures for querying el/key/val-type.
- Rectify incorrectly typed output for `PackedInstances` (reverse) iteration.

## [0.2.0] - 2026-06-17

### Changed
- Extend method coverage for reversed iterators.
- Modify property name querying to properly delineate private content.
- Correct [`README.md`](README.md) for enhanced clarity and to note particular performance advice.
- Modify [`CHANGELOG.md`](CHANGELOG.md) to conform with [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) guidelines.

### Fixed
- Rectify encoding issue for types with numerous integer valued instances.
- Rectify non-compliant function signature for querying property names.
- Rectify equivalence issue when hashing key iterator inputs.

## [0.1.0] - 2026-05-30
Initial release of `BitPackedInstances`.

[Unreleased]: https://github.com/QuantumSavory/BitPackedInstances.jl/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/QuantumSavory/BitPackedInstances.jl/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/QuantumSavory/BitPackedInstances.jl/releases/tag/v0.1.0
