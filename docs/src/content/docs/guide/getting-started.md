---
title: Getting Started
description: Prerequisites, interactive and non-interactive project generation, initial setup, and keeping downstream projects synchronized with Polyform.
---

Polyform is a [Copier](https://copier.readthedocs.io/) template (`_min_copier_version: "9.0.0"`) that scaffolds production-ready Nim, Python, TypeScript/WebAssembly, C/C++ FFI, and Embedded repositories with a unified `just` command surface.

## Prerequisites

Depending on the facets enabled in your target project, install the following tools:

| Tool | Purpose | Required When |
| :--- | :--- | :--- |
| **`uv`** (`uvx`) | Runs `copier` and manages Python virtualenvs (`>=3.9`) | Always (for `uvx copier`) / `has_python=true` |
| **`just`** | Canonical task runner for `setup`, `test`, `lint`, `fmt`, `build` | Always |
| **`nim`** (`>=2.0`) & **`nimble`** | Nim compiler, package manager, and `nph` formatter | `has_nim=true` |
| **`node`** (`>=22`) & **`npm`** | TypeScript build/test toolchain and Astro Starlight docs | `has_typescript=true` or `docs_engine="starlight"` |
| **`cmake`** & C/C++ compiler | Native shared library builds, `scikit-build-core`, and HeaderKit | `has_c_cpp=true` or `python_bridge_strategy in ["naganim", "ctypes_cabi"]` |

## 1. Interactive Project Scaffolding

Run Copier interactively via `uvx` to answer prompts for project identity, language facets, bridge strategies, and documentation:

```bash
uvx copier copy --trust gh:axiomantic/polyform my-project
```

Why `--trust`? Polyform executes post-copy lifecycle tasks defined in `copier.yml` (`git init -q`, `direnv allow` when available, and a summary banner).

## 2. Non-Interactive Generation (`--data` / `-d`)

For CI pipelines, automated scripts, or AI coding agents (`PROMPT_SCAFFOLD.md`), pass `--defaults` along with `-d key=value` overrides:

```bash
# Example 1: Pure Nim library with Starlight docs
uvx copier copy --trust --defaults \
  -d project_name="Fast Graph" \
  -d repo_name="fast-graph" \
  -d package_name="fast_graph" \
  -d github_owner="axiomantic" \
  -d has_nim=true \
  gh:axiomantic/polyform ./fast-graph

# Example 2: Nim + Python native wheel bridged with naganim
uvx copier copy --trust --defaults \
  -d project_name="Fast Bindings" \
  -d has_nim=true \
  -d has_python=true \
  -d python_bridge_strategy="naganim" \
  -d python_freethreaded_ci=true \
  gh:axiomantic/polyform ./fast-bindings

# Example 3: Nim + C/C++ HeaderKit FFI binding
uvx copier copy --trust --defaults \
  -d project_name="LibFoo Nim" \
  -d has_nim=true \
  -d has_c_cpp=true \
  -d c_binding_strategy="headerkit" \
  gh:axiomantic/polyform ./libfoo-nim
```

## 3. Initial Setup & Verification

Every generated repository includes a standardized `justfile`:

```bash
cd my-project

# 1. Install dependencies across all enabled facets (nimble, pip/uv, npm, docs)
just setup

# 2. Execute all enabled test suites (nimble test, pytest, vitest)
just test

# 3. Run code formatters and linters (nph --check, nimble check, ruff, npm run lint)
just lint

# 4. Scan for accidental secrets via gitleaks
just check-secrets
```

## 4. Keeping Downstream Projects Synchronized

Every scaffolded repository commits a `.copier-answers.yml` file recording the exact template version (`_commit`) and facet choices. When Polyform releases new CI workflows, toolchain upgrades, or bug fixes, pull them into your downstream repository with:

```bash
# Inside your downstream project root (with a clean git working tree)
just update-template
# Which runs: uvx copier update --trust
```

If you also want to change a facet on an existing project (for example, adding Python bindings to a pure Nim library), run `uvx copier update --trust` without `--defaults` (or pass `-d has_python=true -d python_bridge_strategy=naganim`).

## 5. Active AI Onboarding & Upgrade Protocol

Every Polyform project includes an active onboarding and migration protocol designed for AI coding assistants (Claude Code, Antigravity, OpenCode, Codex, Cursor):

### Initial Bootstrap Hydration
1. A fresh repository renders `ONBOARDING.md` and prepends an actionable banner to `AGENTS.md`.
2. When an AI assistant opens the project, it reads `AGENTS.md`, detects the banner, and proactively guides the operator through:
   - Baseline toolchain checks (`just setup && just test && just lint && just check-secrets`).
   - Domain architecture interview (entities, module boundaries, invariants) to hydrate placeholder stubs in `AGENTS.md`.
   - Conditional feature configurations (such as choosing between GPU-only vs. all macOS CI for `gh-krun-runner`).
3. Running **`just finish-onboarding`** deletes `ONBOARDING.md`, cleanly strips the banner from `AGENTS.md`, and creates a commit carrying the RFC 822 `Polyform-Template-Ref:` git commit trailer. (Pass `--no-commit` if you prefer to review staged changes and commit manually).

### Upgrade Migration Flow
1. Running **`just update-template`** executes Copier's 3-way merge and automatically invokes `python3 scripts/onboard.py rearm --from <prev> --to <new>`.
2. This inspects the working tree delta (`git diff` and conflict detection), generates a rich `ONBOARDING.md` upgrade playbook detailing modified files and version migration highlights, and re-inserts the banner at line 1 of `AGENTS.md`.
3. In the next agent session, the assistant identifies what changed between versions, assists in resolving any merge conflicts, interviews the operator only on newly added capabilities, and finalizes with `just finish-onboarding`.
