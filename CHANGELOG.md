# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Root Copier megatemplate specification (`copier.yml`) supporting `pure_nim`, `nim_ts_wasm`, `nim_python_wheel`, and `headerkit_binding`.
- Template payload directory (`template/`) with `.copier-answers.yml.jinja` for upstream continuous upgrade tracking.
- Compiler build configuration (`template/nim.cfg`) with deterministic ORC memory management and threading.
- Initial project structure from template.
