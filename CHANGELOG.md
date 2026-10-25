# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Polyform root fixture matrix test runner (tests/test_fixtures.sh), root justfile fixture recipes, and GitHub Actions CI fixture matrix verification for pure_nim, nim_ts_wasm, nim_python_wheel, and headerkit_binding (Task 3.2)
- Root Copier megatemplate specification (`copier.yml`) supporting `pure_nim`, `nim_ts_wasm`, `nim_python_wheel`, and `headerkit_binding`.
- Template payload directory (`template/`) with `.copier-answers.yml.jinja` for upstream continuous upgrade tracking.
- Compiler build configuration (`template/nim.cfg`) with deterministic ORC memory management and threading.
- Initial project structure from template.
- Baseline template files and canonical justfile across all flavors (Task 1.2)
- Implement Flavor B (Nim + TypeScript/WASM bridge) with ESM packaging, Vite runtime, and Vitest suite (Task 2.1)
- Flavor D (HeaderKit C/C++ Binding Extension): headerkit.toml.jinja, include/ C header and implementation, bindings generator script, and test_tripwire symbol verification (Task 2.3)
- GitHub Web UI auto-hydration workflow (.github/workflows/bootstrap.yml) with self-deletion and .copier-answers.yml upstream recording (Task 3.1)
- Implement Flavor C (Nim Native Python Wheel) with scikit-build-core, CMake, ctypes, and pytest (Task 2.2)
- Integrate native Dependabot Nim ecosystem and purge Renimble legacy workflows (Task 4.1)
- Clean root legacy artifacts and establish Polyform storefront (Task 5.2)
- Add Astro Starlight documentation portal templates, tools/docgen.nim, and rendered repo GitHub Actions workflows (ci.yml, docs.yml, auto-tag.yml, momus.yml) (Task 5.1)
- Harden fixture test harness to test Starlight docs build and assert CI workflows, eliminating green mirage (Task 5.3)
- Remediate advanced code review findings (WASM export, FFI lifetime, VitePress purge, docgen paths, CI ordering)

### Removed
- Deprecated template-cleanup.yml workflow and template-cleanup-marker (superseded by bootstrap.yml) (Task 3.1)
