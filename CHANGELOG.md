# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Composable Multi-Facet Scaffolding: Decoupled monolithic flavors into independent composable facet flags (`has_nim`, `has_python`, `has_typescript`, `has_c_cpp`) with conditional bridge strategies (`ts_bridge_strategy`, `python_bridge_strategy`, `c_binding_strategy`).
- Modular Justfile Targets: Added modular language test (`test-nim`, `test-py`, `test-ts`), lint (`lint-nim`, `lint-py`, `lint-ts`), and format recipes in `template/justfile.jinja`, dynamically bound to top-level `test`, `lint`, and `fmt`.
- Composable CI Workflows: Refactored `template/.github/workflows/ci.yml.jinja` into independent matrix jobs (`test-nim`, `test-python`, `test-typescript`) rendered conditionally according to active facets and bridge strategies.
- Expanded Fixture Verification: Six canonical fixture profiles (`fixture-pure-nim`, `fixture-pure-py`, `fixture-pure-ts`, `fixture-nim-ts`, `fixture-nim-py`, `fixture-nim-c`) with negative control assertions ensuring zero language carcasses in single-facet downstream repositories.

### Fixed
- Root Workflow CI Fixes: Added `setup-just@v2` action to `.github/workflows/ci.yml` before fixture execution.
- Bootstrap Workflow: Removed invalid job-level `hashFiles()` evaluation from `.github/workflows/bootstrap.yml`.
- Root Docs & Release Workflows: Added existence guards to prevent failing on non-existent `mkdocs.yml` or root `.nimble` builds in Copier template repository.

## [0.1.6] - 2026-10-26

### Changed
- Default Momus Review Model: Updated default `momus_model` in `copier.yml` to `~anthropic/claude-sonnet-latest` (OpenRouter family-floating alias for latest Claude Sonnet). Updated `PROMPT_SCAFFOLD.md` and test fixture matrix assertions.

## [0.1.5] - 2026-10-26

### Added
- Momus Environment Scoping: Added `environment: code-review` and `secrets: inherit` to `.github/workflows/momus.yml.jinja` to support repositories with scoped environment secrets out of the box.

## [0.1.4] - 2026-10-25

### Security
- Momus Workflow Hardening: Added default-deny `permissions: {}` at top-level, PR-level concurrency control, coarse pre-filtering `if:` condition at caller job level to prevent bot spam or non-trigger comments from scheduling runner VMs, and explicit `only_collaborators: true` to prevent external PRs from draining LLM API quotas.
- Fleet Workflow Hardening: Declared top-level `permissions: {}` across all template workflows (`ci.yml.jinja`, `cibuildwheel.yml.jinja`, `docs.yml.jinja`, `auto-tag.yml.jinja`, `dependabot-verify.yml.jinja`) and root workflows, strictly granting least-privilege permissions only at job level.
- Shell Injection Sanitization: Sanitized expression interpolations in `bootstrap.yml` to pass dynamic values strictly via `env:` blocks rather than inline inside bash `run:` scripts.
- Documentation & Guidance: Updated `NEXT_STEPS.md.jinja` and `AGENTS.md.jinja` with security gating details (collaborator gating and maintainer `/ai-review` triggering on external forks).

## [0.1.3] - 2026-10-25

### Fixed
- Dependency Automation: Purged unsupported `package-ecosystem: "nimble"` from `.github/dependabot.yml.jinja` to prevent GitHub Dependabot schema errors.
- Dependabot Configuration: Kept Dependabot strictly scoped to supported ecosystems (`github-actions`, plus `npm` and `pip` when appropriate).

### Added
- Renovate Configuration: Added `.github/renovate.json.jinja` and root `.github/renovate.json` with native `nimble.enabled: true` for Renovate bot integration.
- Dependency Verification: Updated `dependabot-verify.yml` to validate both Dependabot and Renovate configurations and assert absence of unsupported ecosystems.

## [0.1.2] - 2026-10-25

### Added
- Gitleaks secret scanner integration: v8.24.0 in `.pre-commit-config.yaml.jinja`, `gitleaks/gitleaks-action@v2` job in `ci.yml.jinja`, and `check-secrets` recipe in `justfile.jinja` and root `justfile`
- Default Momus model updated to `anthropic/claude-sonnet-5` in `copier.yml`
- `PROMPT_SCAFFOLD.md` AI assistant protocol with directory guard, global AGENTS.md greenfield invariant, Copier schema question proxying, and setup/test verification
- AI Coding Assistant scaffolding documentation in `README.md`
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
- Momus configuration options (.momus.yaml), persistent NEXT_STEPS.md onboarding checklists, update-template recipe, and post-copy tailored ANSI terminal Rider
- Add optional justfile.local extension hook to template and root justfiles for local recipe overrides
- Remediate advanced code review findings (WASM export, FFI lifetime, VitePress purge, docgen paths, CI ordering)

### Removed
- Deprecated template-cleanup.yml workflow and template-cleanup-marker (superseded by bootstrap.yml) (Task 3.1)
