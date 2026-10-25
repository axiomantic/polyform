# Polyform: Universal Polyglot Megatemplate

[![CI](https://github.com/axiomantic/polyform/actions/workflows/ci.yml/badge.svg)](https://github.com/axiomantic/polyform/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted.json)](https://github.com/copier-org/copier)

**Polyform** is an industrial-grade polyglot megatemplate engineered for production Nim applications and native bridges. Powered by [Copier](https://copier.readthedocs.io/), Polyform delivers clean multi-flavor scaffolding, seamless upgrades via `copier update`, and closed-circuit tooling across pure Nim, TypeScript/WASM, Python native wheels, and C/C++ foreign function interfaces.

---

## Architectural Flavor Matrix

Polyform provides four out-of-the-box architectural flavor topologies:

| Flavor | Target Architecture | Toolchain & Runtime | Packaging & DevEx |
| :--- | :--- | :--- | :--- |
| **`pure_nim`** | Pure Nim Library / CLI | Nim 2.2+, `nimble` | Single or multi-file layout, Starlight docs portal |
| **`nim_ts_wasm`** | TypeScript WebAssembly Bridge | Nim C-backend + Emscripten / WASM | ESM bindings, TypeScript types, Vitest test suite, npm packaging |
| **`nim_python_wheel`** | Nim Native Python Wheel | `scikit-build-core`, CMake, `ctypes` | PEP 621 wheels, `cibuildwheel` matrix, pytest test suite |
| **`headerkit_binding`** | HeaderKit C/C++ Binding Extension | HeaderKit FFI wrapper, C header | Automated FFI generator, foreign symbol tripwire verification |

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
> "Read `PROMPT_SCAFFOLD.md` and help me scaffold a new Nim project."

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
