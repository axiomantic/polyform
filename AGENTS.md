# Polyform Developer & Agent Guide

This document defines architecture, workflows, and invariants for developing the **Polyform** megatemplate repository.

---

## Architecture & Layout

Polyform is a Copier template repository structured into two distinct layers:

```
polyform/
├── copier.yml                 # Copier schema, questions, choices, and file exclusion rules
├── template/                  # Template payload rendered into downstream projects
│   ├── .copier-answers.yml.jinja
│   ├── justfile.jinja         # Canonical downstream command surface
│   ├── {{ package_name }}.nimble.jinja
│   ├── src/                   # Core Nim source templates
│   ├── tests/                 # Nim test templates
│   ├── ts/                    # TypeScript / WASM bridge (Flavor B)
│   ├── src_py/                # Python ctypes wrapper (Flavor C)
│   ├── tests_py/              # Pytest test suite (Flavor C)
│   ├── include/               # C/C++ foreign headers (Flavor D)
│   └── .github/               # Workflows and Dependabot templates
├── tests/
│   └── test_fixtures.sh       # Comprehensive 4-flavor rendering and verification harness
├── .github/
│   └── workflows/
│       ├── ci.yml             # Matrix CI running test_fixtures.sh across Ubuntu/macOS/Windows
│       ├── bootstrap.yml      # GitHub Web UI auto-hydration workflow
│       └── dependabot-verify.yml # Dependabot schema validator
└── justfile                   # Polyform maintainer commands (canonical test surface)
```

---

## Build & Test Commands

Polyform maintainers execute all workflows via `just`:

| Task | Command | Description |
|---|---|---|
| Test All | `just test` | Run test suites across all 4 flavor fixtures |
| Matrix Fixtures | `just fixtures` | Render, setup, lint, and test all 4 flavor fixtures |
| Lint | `just lint` | Run linters across all 4 flavor fixtures |
| Clean | `just clean` | Remove temporary fixture staging directories |
| Single Flavor Test | `just test-fixtures flavor=nim_ts_wasm` | Target specific flavor verification |

---

## Architectural Invariants

1. **Jinja Whitespace Discipline**:
   All conditional recipe blocks in `template/justfile.jinja` must use whitespace-trimming tags (`{%- if %}`, `{%- elif %}`, `{%- endif %}`) to avoid orphaned indentation in rendered `justfile`s.

2. **Copier Exclusion Precision**:
   Directory-level exclusions in `copier.yml` must match directory names directly (e.g. `ts`, `src_py`, `tests_py`, `include`) to prevent empty carcass folders from leaking into incompatible flavors.

3. **Anti-Green-Mirage Verification**:
   All fixture test suites (`test_fixtures.sh`, Vitest, pytest, nimble test) must assert exact expected equality (`assert actual == expected`) and test negative controls / type contracts.

4. **Zero Untracked / Dead Artifacts**:
   Root Nim project files (`project_name.nimble`, `src/project_name.nim`, etc.) are purged in favor of `template/` and fixture-based validation.

5. **Canonical Command Surface**:
   Dev workflows must always be exposed as `just` recipes rather than ad-hoc shell commands.
