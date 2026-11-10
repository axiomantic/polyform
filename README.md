# Polyform: Composable Multi-Target Copier Megatemplate

[![Docs](https://img.shields.io/badge/docs-axiomantic.github.io%2Fpolyform-blue.svg)](https://axiomantic.github.io/polyform/)
[![CI](https://github.com/axiomantic/polyform/actions/workflows/ci.yml/badge.svg)](https://github.com/axiomantic/polyform/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted.json)](https://github.com/copier-org/copier)

**Polyform** is a composable Copier megatemplate for multi-target Nim, Python, TypeScript/WASM, C/C++ HeaderKit FFI, and Embedded RTOS projects. Powered by [Copier](https://copier.readthedocs.io/), Polyform delivers clean composable facet scaffolding, seamless upgrades via `copier update`, and closed-circuit tooling across pure Nim, TypeScript/WASM, Python native wheels, C/C++ foreign function interfaces, and freestanding embedded microcontrollers.

> 📖 **Official Documentation**: Guides, architecture walk-throughs, and complete configuration options are available at **[https://axiomantic.github.io/polyform/](https://axiomantic.github.io/polyform/)**.

---

## Composable Language & Target Facet Matrix

Rather than locking projects into rigid silos, Polyform features an orthogonal, composable facet matrix. You can toggle any valid combination of languages, runtime bridge strategies, and foreign interfaces:

### Core Language & Environment Facets

| Facet | Description | Included Toolchains & Capabilities |
| :--- | :--- | :--- |
| **`has_nim`** | Nim language toolchain | Nim 2.2+, `nimble`, `nph` formatter, Nimony (Nim 3.0 preview) CI |
| **`has_python`** | Python environment & wheels | `uv`, `ruff`, `pytest`, PEP 621, PEP 703 Free-Threaded Python (`3.13t` & `3.14t`) |
| **`has_typescript`** | TypeScript & JavaScript bridge | Node.js 24, Vite, `vitest`, `tsconfig`, npm packaging |
| **`has_c_cpp`** | Foreign C/C++ integration | C/C++ headers, CMake build harness, static/shared library artifacts |
| **`has_embedded`** | Freestanding Embedded profile | Standalone ARC memory management, zero OS dependencies, RTOS headers |

### Native Bridge Strategies

When combining multiple language facets, Polyform wires idiomatic native bridges:

- **`python_bridge_strategy`**:
  - `naganim`: High-performance CPython `abi3`/`abi3t` extension module with CFFI fallback.
  - `ctypes_cabi`: Pure C ABI dynamic library with Python `ctypes` bindings.
  - `none`: Disables Python FFI bridging.
- **`ts_bridge_strategy`**:
  - `wasm`: Compiles native code to WebAssembly with ESM runtime via `@axiomantic/nimts`.
  - `napi`: Compiles Node.js native addon (N-API).
  - `none`: Disables TypeScript bridging.
- **`c_binding_strategy`**:
  - `headerkit`: Automated declarative FFI generation via `headerkit>=0.51.0` and `headerkit.toml`.
  - `cmake_static`: Standard CMake compilation to foreign archive without automated generator.
  - `none`: Disables foreign binding generation.
- **`embedded_runtime_target`**:
  - `standalone_arc`: Freestanding C translation with standalone ARC (`--os:standalone --mm:arc`).
  - `zephyr`: Zephyr RTOS module integration.
  - `freertos`: FreeRTOS task and static allocation profile.
  - `none`: Disables embedded target orientation.

### Quick-Select Flavor Presets

For standard project archetypes, Polyform provides 4 pre-configured quick-select flavor presets that automatically set baseline facets:

| Flavor Preset | Archetype | Active Facets & Bridges | Primary Use Case |
| :--- | :--- | :--- | :--- |
| **`pure_nim`** | Pure Nim Library / CLI | `has_nim=true` | High-performance CLI tools, servers, libraries |
| **`nim_ts_wasm`** | TypeScript / WASM Bridge | `has_nim=true`, `has_typescript=true`, `ts_bridge_strategy="wasm"` | In-browser computation, full-stack web, npm packages |
| **`nim_python_wheel`** | Native Python Wheel | `has_nim=true`, `has_python=true`, `python_bridge_strategy="naganim"` | PyPI distribution, numerical kernels, data science extensions |
| **`headerkit_binding`** | HeaderKit C/C++ Binding | `has_nim=true`, `has_c_cpp=true`, `c_binding_strategy="headerkit"` | Seamless FFI wrapper around foreign C/C++ libraries |

> **Note on Custom Combinations:** Facets are completely orthogonal. You can freely combine `has_python=true` + `has_c_cpp=true` + `c_binding_strategy="headerkit"` without Nim, or combine all facets (`has_nim` + `has_python` + `has_typescript` + `has_c_cpp` + `has_embedded`) for unified cross-platform distribution.

---

## Getting Started

### 1. Interactive Scaffolding (CLI)

Generate a new repository directly from GitHub using Copier:

```bash
# Recommended zero-install invocation via uvx
uvx copier copy --trust gh:axiomantic/polyform my-new-project

# Or using local Copier installation
copier copy --trust gh:axiomantic/polyform my-new-project
```

Copier prompts interactively for project metadata, flavor topology, documentation engine, and optional integrations.

### 2. GitHub Web UI Scaffolding (Zero-CLI)

You can generate downstream repositories directly from GitHub's Web UI:
1. Click **Use this template** > **Create a new repository**.
2. Once created, Polyform's automated GitHub Actions bootstrap workflow ([`bootstrap.yml`](.github/workflows/bootstrap.yml)) detects initial repository creation.
3. The workflow runs Copier auto-hydration with your repository name, initializes git tracking, self-deletes the bootstrap harness, and commits the clean project payload directly to `main`.

### 3. Scaffold with an AI Coding Assistant

When pairing with an AI coding assistant (Claude Code, Antigravity, OpenCode, Cursor, Codex), use [`PROMPT_SCAFFOLD.md`](PROMPT_SCAFFOLD.md) to safely scaffold new projects with zero guessing.

Instruct your assistant:
> "Read `PROMPT_SCAFFOLD.md` and help me scaffold a new project with Polyform."

You can also register the greenfield invariant in your global `~/AGENTS.md` (or `~/.gemini/AGENTS.md`):

```markdown
## Greenfield Invariant
When new proj, ASK user if they want Polyform template. If yes, read:
`~/.local/share/polyform/PROMPT_SCAFFOLD.md` (clone `gh:axiomantic/polyform` there if miss).
```

The assistant will:
1. Ask and confirm your project intent and check the target directory.
2. Proxy Copier configuration questions (flavor, metadata, licensing, review tools) rather than hallucinating answers.
3. Execute non-interactive `uvx copier copy` without blocking on interactive prompts.
4. Run `just setup`, `just test`, `just lint`, and `just check-secrets` to verify the generated project is 100% green before handing off.

---

## Downstream Project Workflow

Every generated project shares the canonical `just` command surface:

```bash
just setup   # Install all flavor toolchain dependencies (npm, pip, nimble)
just test    # Run full test suite (nimble test, vitest, pytest, tripwire)
just lint    # Run code formatting and linter checks (nph, ruff, tsc)
just fmt     # Auto-format codebase across all languages
just build   # Compile distribution artifacts (binaries, wheels, WASM, docs)
```

### Upgrading Downstream Projects

Downstream projects maintain `.copier-answers.yml`, allowing seamless non-destructive updates when Polyform releases improvements:

```bash
cd my-new-project
uvx copier update --trust
```

---

## Repository Development & Verification

When developing Polyform itself, test the full multi-flavor fixture matrix locally:

```bash
# Run fixture test suites across all 4 flavors
just test

# Run full matrix fixture verification (render, lint, test)
just fixtures

# Test a single flavor
just test-fixtures flavor=nim_python_wheel
```

---

## Conventions & Standards

- **Formatting Authority:** `nph` is the canonical formatter for Nim code and `.nimble` manifests.
- **Dependency Automation:** Automated via Renovate (`.github/renovate.json`) and GitHub Dependabot (`.github/dependabot.yml`).
- **Canonical Command Surface:** Dev workflows are encoded as `just` recipes (`justfile`).
- **Axiomantic Quality Invariants:** Verified via the Three-Key Gate, zero dead code/stubs, and anti-green-mirage assertions.
