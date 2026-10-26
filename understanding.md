# Understanding Polyform: Axiomantic Polyglot Megatemplate

## Executive Summary & Mission
Polyform (`axiomantic/polyform`) is the next-generation template architecture evolving `template-nim` into a universal, multi-flavor, multi-lingual repository generator. Governed by Axiomantic production-grade standards (audit-driven tooling, zero shelfware, zero green mirages), Polyform solves two longstanding friction points in repository template systems:
1. **Mono-flavor rigidity**: Traditional templates force a single monolithic project structure or require maintaining N separate out-of-sync template repositories. Polyform unifies pure Nim, TypeScript/WASM, Python native wheels, and HeaderKit FFI bindings under a single Copier megatemplate.
2. **One-way generation loss**: Traditional GitHub template repositories ("Use this template") perform a static branch copy or crude placeholder find/replace (`template-cleanup.yml`), permanently severing downstream repositories from upstream bugfixes, CI updates, and tool upgrades. Polyform preserves the upstream linkage via Copier's 3-way merge engine and recorded answers.

---

## 1. Copier Architecture & Subdirectory Strategy

### 1.1 Host Environment & Empirical Tool Verification
Empirical execution on host system (`aarch64-apple-darwin`):
- `uv`: `0.11.24` (Homebrew 2026-06-23)
- `uvx copier`: `9.19.1`
- `nim`: `2.2.6+`
- `nph`: `0.7.0` (pinned formatting authority)

### 1.2 Directory Topology (`_subdirectory: template`)
In Copier v9+, `copier.yml` supports the `_subdirectory` directive. Setting `_subdirectory: template` partitions the Polyform repository into two isolated tiers:

```text
polyform/ (Repository Root)
├── copier.yml                          # Template manifest, questions, conditional rules
├── justfile                            # Root development & test runner for Polyform itself
├── tests/                              # Polyform root verification harness
│   └── test_fixtures.sh               # Renders & verifies all flavors in /tmp
├── .github/
│   └── workflows/
│       ├── ci.yml                      # Verifies all template flavor fixtures on CI
│       └── bootstrap.yml               # GitHub UI auto-hydration workflow (self-deleting)
├── docs/                               # Polyform documentation
└── template/                           # PAYLOAD DIRECTORY (_subdirectory: template)
    ├── .copier-answers.yml.jinja       # MANDATORY: Upstream answer persistence
    ├── justfile.jinja                  # Downstream project canonical command surface
    ├── src/
    │   └── {{ project_name }}.nim.jinja
    ├── {{ project_name }}.nimble.jinja
    ├── tests/
    │   └── test_{{ project_name }}.nim.jinja
    ├── package.json.jinja              # (Flavor B: nim_ts_wasm)
    ├── tsconfig.json                   # (Flavor B: nim_ts_wasm)
    ├── pyproject.toml.jinja            # (Flavor C: nim_python_wheel)
    ├── CMakeLists.txt.jinja            # (Flavor C: nim_python_wheel)
    └── headerkit.toml.jinja            # (Flavor D: headerkit_binding)
```

**Architectural Invariant**: Files at repository root outside `template/` (e.g. Polyform's internal `justfile`, root CI, test runner) are strictly excluded from downstream generation. Downstream repositories only receive files rendered from `template/`.

### 1.3 Conditional Inclusion & Jinja `_exclude` Evaluation
Empirical experimentation conducted with Copier 9.19.1 confirmed the mechanics of conditional generation. Copier supports dynamic exclusion in `copier.yml`:

```yaml
_subdirectory: template
_answers_file: .copier-answers.yml

_exclude:
  - "{% if flavor != 'nim_ts_wasm' %}package.json{% endif %}"
  - "{% if flavor != 'nim_ts_wasm' %}tsconfig.json{% endif %}"
  - "{% if flavor != 'nim_ts_wasm' %}ts/**{% endif %}"
  - "{% if flavor != 'nim_python_wheel' %}pyproject.toml{% endif %}"
  - "{% if flavor != 'nim_python_wheel' %}CMakeLists.txt{% endif %}"
  - "{% if flavor != 'headerkit_binding' %}headerkit.toml{% endif %}"
  - "{% if flavor != 'headerkit_binding' %}include/**{% endif %}"
```

**Empirical Result**: When Jinja evaluates to an empty string, Copier ignores the exclude entry. When Jinja evaluates to a non-empty string/pattern, the target is excluded from the generated project. This avoids mangling filenames in git with nested `{% if %}` template tags.

### 1.4 Downstream Answer Recording & Update Safety (`.copier-answers.yml`)
**Critical Empirical Finding**:
In Copier 9.19.1, setting `_answers_file: .copier-answers.yml` in `copier.yml` is **not sufficient by itself**. The file `template/.copier-answers.yml.jinja` MUST exist containing:
```jinja
{{ _copier_answers|to_nice_yaml -}}
```
Without this file, Copier copies the template but emits zero answer files, permanently breaking downstream `copier update`. When present, Copier records:
```yaml
_commit: <git-sha-or-tag>
_src_path: gh:axiomantic/polyform
flavor: nim_ts_wasm
project_name: my_app
author_name: Dev
```
Downstream consumers can run:
```bash
uvx copier update --trust
```
Copier computes a 3-way merge (`git merge-file`) between the previous template tag, the new template tag, and the downstream repository, cleanly applying upstream template improvements while preserving custom user modifications.

---

## 2. Dual Entrypoint Mechanics

Polyform supports two distinct initiation pathways with reference parity.

### 2.1 Entrypoint A: Modern CLI (`uvx copier copy`)
The primary workflow for engineers utilizing modern terminal tooling:
```bash
uvx copier copy gh:axiomantic/polyform my-project
```
- Fully interactive question prompts (prompting for project name, flavor, license, author info).
- Non-interactive batch mode supported via data flags:
  ```bash
  uvx copier copy -d project_name="tensor_ops" -d flavor="nim_ts_wasm" --defaults gh:axiomantic/polyform ./tensor_ops
  ```
- Renders directly into `./tensor_ops` with `.copier-answers.yml` pre-populated.

### 2.2 Entrypoint B: GitHub Web UI ("Use this template") with Auto-Hydration
When an operator creates a repository using GitHub's "Use this template" button, GitHub does not execute Copier; it copies the repository contents verbatim.

To achieve reference parity with the CLI entrypoint, Polyform implements an automated self-deleting hydration workflow: `.github/workflows/bootstrap.yml`.

#### Auto-Hydration Lifecycle & Invariants
1. **Sentinel Guard**: Checks whether the repo is in an unhydrated state:
   ```yaml
   if: github.repository != 'axiomantic/polyform' && hashFiles('copier.yml') != ''
   ```
2. **Context Derivation**: Extracts repository metadata from GitHub environment variables:
   - `REPO_OWNER="${GITHUB_REPOSITORY%/*}"`
   - `REPO_NAME="${GITHUB_REPOSITORY#*/}"`
   - Description from GitHub API or event payload.
3. **In-Place Hydration Execution**:
   ```bash
   uvx copier copy --trust --defaults \
     -d project_name="${REPO_NAME}" \
     -d repo_owner="${REPO_OWNER}" \
     -d flavor="pure_nim" \
     . /tmp/hydrated
   ```
4. **Trunk Replacement & Self-Deletion Invariant**:
   - The contents of `/tmp/hydrated` are copied into the repository root.
   - The bootstrap workflow (`.github/workflows/bootstrap.yml`), `copier.yml`, and `template/` directory are removed via `git rm`.
   - `.copier-answers.yml` is committed with `_src_path: gh:axiomantic/polyform`.
   - Pushed via `github-actions[bot]` with `[skip ci]`.
   - **Idempotency Guarantee**: Because `bootstrap.yml` deletes itself in the initial hydration commit, subsequent pushes will never re-trigger hydration.

---

## 3. Polyglot Flavor Topologies

Polyform codifies four standardized production flavors.

### 3.1 Flavor A: `pure_nim` (Axiomantic Gold Standard)
The benchmark layout for native Nim libraries, tools, and daemons.
- **Source Layout**: `src/{{ project_name }}.nim` (single-file) or `src/{{ project_name }}/` (multi-file).
- **Tooling & Linter Authority**: `nph@0.7.0` pinned across `.pre-commit-config.yaml`, `ci.yml`, and `justfile`.
- **Command Surface**: `justfile` exposing canonical recipes:
  - `just test`: Runs stdlib `unittest` via `nimble test`.
  - `just lint`: Runs `nph --check` and `nimble check`.
  - `just fmt`: In-place formatting via `nph`.
  - `just docs`: Extracts AST docstrings via `tools/docgen.nim` and serves Astro Starlight.
  - `just docs-build`: Static build of Starlight documentation.
  - `just build`: Release build via `nimble build -d:release`.

### 3.2 Flavor B: `nim_ts_wasm` (Nim + TypeScript WebAssembly Bridge)
Empirically modeled on `/Users/eek/Development/nimts`:
- **Package Manifest**: `package.json` with ESM exports (`type: module`), pointing to `./dist/index.js` and `./dist/index.d.ts` (lines 1-35).
- **TypeScript Configuration**: `tsconfig.json` targeting `ES2022`, `module: "ESNext"`, `moduleResolution: "bundler"`, `declaration: true` (lines 1-20).
- **WASM Build Pipeline**: Compiles Nim to WebAssembly using `--cpu:wasm32 --os:standalone` with memory-safe ORC management (`--mm:orc`).
- **Unified Test Gate**:
  - Nim-level unit tests via `nimble test`.
  - TS/WASM runtime tests via `vitest`.
  - Canonical `just test` executes both in sequence.

### 3.3 Flavor C: `nim_python_wheel` (Nim to CPython Native Wheels)
Empirically modeled on `/Users/eek/Development/headerkit/docs/guides/nim-python-packaging.md`:
- **Build System**: `pyproject.toml` with `scikit-build-core>=0.9.0` build-backend (lines 115-130).
- **Compilation Engine**: `CMakeLists.txt` executing `nim c --app:lib --mm:orc --threads:on` (lines 131-155).
- **Crucial Runtime Invariants**:
  1. `NimMain()`: Must be invoked idempotently before executing any exported proc.
  2. `setupForeignThreadGc()`: Must be invoked on entry to all exported procs called from Python/foreign threads to prevent thread-local heap corruption.
  3. Deterministic Destructors: Python wrappers hook `__del__` to explicit Nim deallocation routines.
- **Cross-Platform Distribution**: Automated wheel generation across Linux (Docker container with volume-mounted store), macOS, and Windows via `cibuildwheel` (HeaderKit `docs/guides/cibuildwheel.md` lines 33-67).

### 3.4 Flavor D: `headerkit_binding` (Turnkey C/C++ FFI)
Empirically modeled on HeaderKit's scaffolding and writer engines:
- **Manifest**: `headerkit.toml` defining target language (`nim`), C/C++ header search paths (`-I`), preprocessor definitions (`-D`), and dynamic library links (`-l`).
- **Scaffolding Integration**: Direct compatibility with HeaderKit's `CopierBYOScaffolder` plugin (`examples/scaffolding/copier_scaffolder.py` lines 37-74).
- **Memory & Compiler Flags (`nim.cfg`)**: Automatically configured with `--mm:orc`, `--threads:on`, `--passC:"-I..."`, and `--backend:cpp` if AST analysis detects C++ classes or template-ids (`docs/guides/scaffolding.md` lines 61-96).
- **Dual Verification**: Low-level tripwire verification (`test_tripwire.nim` for dynamic symbol resolution) paired with high-level idiomatic API tests.

---

## 4. Polyform Root Verification Harness

To eliminate the "Green Mirage" and ensure that the megatemplate never produces broken repositories, Polyform incorporates an automated fixture test harness.

### 4.1 Test Harness Topology (`tests/test_fixtures.sh`)
The root verification suite performs an exhaustive end-to-end matrix render:
```bash
#!/usr/bin/env bash
set -euo pipefail

FLAVORS=("pure_nim" "nim_ts_wasm" "nim_python_wheel" "headerkit_binding")
FIXTURE_ROOT=$(mktemp -d /tmp/polyform-fixtures-XXXXXX)
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

for FLAVOR in "${FLAVORS[@]}"; do
  echo "=== [TEST] Rendering fixture for flavor: ${FLAVOR} ==="
  TARGET="${FIXTURE_ROOT}/${FLAVOR}"
  uvx copier copy --trust --defaults -d project_name="fixture_${FLAVOR}" -d flavor="${FLAVOR}" . "${TARGET}"
  
  # Verify Key 1 (Syntax / Linting)
  (cd "${TARGET}" && just lint)
  
  # Verify Key 2 (Tests & Compilability)
  (cd "${TARGET}" && just test)
  
  # Verify Answers File Exists
  test -f "${TARGET}/.copier-answers.yml"
done
```

### 4.2 CI Matrix Pipeline (`.github/workflows/ci.yml`)
- Runs on GitHub Actions matrix: `ubuntu-latest`, `macos-latest`, `windows-latest`.
- Pre-installs Nim 2.2.6+, Node 20+, Python 3.12+, `just`, `nph@0.7.0`, and `uv`.
- Renders all four fixtures and executes `just lint` and `just test` against every flavor.

---

## 5. Summary of Architectural Decisions & Next Steps
1. **Adopt `_subdirectory: template`**: Clean separation of polyform build tooling and downstream deliverables.
2. **Standardize on `copier.yml` with Jinja `_exclude`**: Clean file hierarchy without nested conditional directory names.
3. **Commit `.copier-answers.yml.jinja`**: Guarantees downstream `copier update` compatibility.
4. **Implement self-deleting `.github/workflows/bootstrap.yml`**: Full feature parity between CLI and GitHub Web UI.
5. **Proceed to Stage 2 (System Architecture & Design)**: Author `design.md` detailing exact Jinja templates, variable schemas, and flavor layout files.
