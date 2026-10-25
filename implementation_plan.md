# Implementation Plan: Polyform Megatemplate

## 1. Swarm Roster & Role Mapping
| Worker Name | Persona | Role | Assigned Subsystems |
| :--- | :--- | :--- | :--- |
| `@polyform-architect` | Topomancer | Staff Systems Architect | Copier schema (`copier.yml`), template payload topology, baseline templates |
| `@polyform-implementer` | Poly-Synthesizer | DevEx & Implementation Lead | Flavors B/C/D matrix, bootstrap workflow, canonical `justfile`, `README.md` |
| `@polyform-auditor` | Crucible-Watch | Verification & Adversarial Auditor | Fixture test harness (`tests/test_fixtures.sh`), root CI, Three-Key gate audits |

---

## 2. Distributed Locking & Concurrency Schedule
To eliminate merge collisions, workers must acquire atomic Rhizo leases prior to mutating shared files:
- **Lock Target**: `file:copier.yml`
  - *Owner*: `@polyform-architect`
  - *Command*: `rhizo lock file:copier.yml 600 --fencing`
- **Lock Target**: `file:template/justfile.jinja`
  - *Owner*: `@polyform-implementer`
  - *Command*: `rhizo lock file:template/justfile.jinja 600 --fencing`
- **Lock Target**: `file:tests/test_fixtures.sh`
  - *Owner*: `@polyform-auditor`
  - *Command*: `rhizo lock file:tests/test_fixtures.sh 600 --fencing`

---

## 3. Vine Strand Lifecycle & Verification Matrix
All development tracks execute in isolated Rift strands (`vine new <strand>`):
1. **Provision Strand**:
   ```bash
   vine new <task_id> --branch strand/<task_id>
   ```
2. **Execute Work Inside Strand**:
   - Write files and implement Jinja templates.
   - Run local lint and formatting checks.
3. **Three-Key Gate Verification**:
   - **Key 1 (Mechanical)**: In-memory conflict pre-check (`git merge-tree --write-tree`).
   - **Key 2 (Semantic & Changelog)**: `vine submit --author <worker>` (evaluates test suite and changelog).
   - **Key 3 (Adversarial Audit)**: Independent auditor runs `vine audit approve --auditor polyform-auditor`.
4. **Trunk Weaving**:
   - Lead orchestrator fast-forwards verified branch into main:
     ```bash
     vine weave && rhizo unlock <lock_target>
     ```

---

## 4. Phase-by-Phase Task Checklist

### Phase 1: Core Engine Primitives & Payload Partitioning
- [x] **Task 1.1: Root Copier Specification & Base Template Payload** (`@polyform-architect`)
  - *Strand*: `strand/copier-core-scaffold`
  - *Lock*: `rhizo lock file:copier.yml 600 --fencing`
  - *Provider*: `copier.yml`, `template/.copier-answers.yml.jinja`, `template/nim.cfg`
  - *Consumer / Call-Site*: `uvx copier copy` invocation engine
  - *Replacement Deletion*: Move root-level project files into `template/` and remove un-templated root Nim files
  - *Holistic Verification*: `uvx copier copy --trust --defaults . /tmp/test-pure-nim` renders cleanly with `.copier-answers.yml`
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave && rhizo unlock file:copier.yml`

- [x] **Task 1.2: Baseline Template Files & Canonical Justfile** (`@polyform-implementer`)
  - *Strand*: `strand/baseline-templates`
  - *Lock*: `rhizo lock file:template/justfile.jinja 600 --fencing`
  - *Provider*: `template/justfile.jinja`, `template/.pre-commit-config.yaml.jinja`, `template/README.md.jinja`, `template/AGENTS.md.jinja`, `template/CHANGELOG.md.jinja`, `template/LICENSE.jinja`, `template/{{ package_name }}.nimble.jinja`, `template/src/{{ package_name }}.nim.jinja`, `template/tests/test_{{ package_name }}.nim.jinja`
  - *Consumer / Call-Site*: Downstream project root on fresh copy
  - *Holistic Verification*: Rendered project passes `just setup`, `just lint`, and `just test`
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave && rhizo unlock file:template/justfile.jinja`

### Phase 2: Polyglot Flavor Matrix
- [x] **Task 2.1: Flavor B (Nim + TypeScript/WASM)** (`@polyform-implementer`)
  - *Strand*: `strand/flavor-ts-wasm`
  - *Provider*: `template/package.json.jinja`, `template/tsconfig.json.jinja`, `template/vitest.config.ts.jinja`, `template/scripts/compile_wasm.sh.jinja`, `template/ts/index.ts.jinja`, `template/ts/runtime.ts.jinja`, `template/ts/types.ts.jinja`, `template/tests/test_ts_bridge.ts.jinja`
  - *Consumer / Call-Site*: `npm test` and `npm run build` in rendered project
  - *Holistic Verification*: Render `flavor: nim_ts_wasm` fixture, verify `just setup`, compile WASM, and pass `vitest`
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave`

- [x] **Task 2.2: Flavor C (Nim Native Python Wheel)** (`@polyform-implementer`)
  - *Strand*: `strand/flavor-python-wheel`
  - *Provider*: `template/pyproject.toml.jinja`, `template/CMakeLists.txt.jinja`, `template/src_py/{{ package_name }}/__init__.py.jinja`, `template/src_py/{{ package_name }}/py.typed`, `template/tests_py/test_{{ package_name }}.py.jinja`, `template/.github/workflows/cibuildwheel.yml.jinja`
  - *Consumer / Call-Site*: `pytest tests_py/` and `python -m build --wheel` in rendered project
  - *Holistic Verification*: Render `flavor: nim_python_wheel` fixture, build extension library with CMake, execute pytest
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave`

- [x] **Task 2.3: Flavor D (HeaderKit C/C++ Binding Extension)** (`@polyform-architect`)
  - *Strand*: `strand/flavor-headerkit`
  - *Provider*: `template/headerkit.toml.jinja`, `template/include/{{ package_name }}.h.jinja`, `template/scripts/generate_bindings.py.jinja`, `template/tests/test_tripwire.nim.jinja`
  - *Consumer / Call-Site*: `nimble test` and HeaderKit scaffolder in downstream project
  - *Holistic Verification*: Render `flavor: headerkit_binding` fixture, verify C header symbol linking passes `test_tripwire`
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave`

### Phase 3: Dual Entrypoint & Root Verification Harness
- [x] **Task 3.1: GitHub Web UI Auto-Hydration Workflow** (`@polyform-architect`)
  - *Strand*: `strand/bootstrap-workflow`
  - *Provider*: `.github/workflows/bootstrap.yml`
  - *Consumer / Call-Site*: GitHub Actions initial push runner on newly templated repo
  - *Replacement Deletion*: Delete deprecated `.github/workflows/template-cleanup.yml`
  - *Holistic Verification*: Local dry-run of hydration script with temporary staging folder, verifying `.git` protection and self-deletion
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave`

- [x] **Task 3.2: Polyform Root Fixture Test Suite & CI Matrix** (`@polyform-auditor`)
  - *Strand*: `strand/root-verification`
  - *Lock*: `rhizo lock file:tests/test_fixtures.sh 600 --fencing`
  - *Provider*: `tests/test_fixtures.sh`, root `justfile`, root `.github/workflows/ci.yml`
  - *Consumer / Call-Site*: Polyform repository CI and local `just test`
  - *Holistic Verification*: Execute `tests/test_fixtures.sh` on all 4 flavors (`pure_nim`, `nim_ts_wasm`, `nim_python_wheel`, `headerkit_binding`), confirming 100% pass rate
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave && rhizo unlock file:tests/test_fixtures.sh`

### Phase 4: Native Dependabot Nim Ecosystem Integration
- [x] **Task 4.1: Dependabot Nim Integration & Renimble Purge** (`@polyform-implementer`)
  - *Strand*: `strand/dependabot-nim-integration`
  - *Provider*: `template/.github/dependabot.yml.jinja`, `.github/dependabot.yml`, `template/.github/workflows/dependabot-verify.yml.jinja`, `.github/workflows/dependabot-verify.yml`
  - *Consumer / Call-Site*: GitHub Dependabot native ecosystem config and CI verification runner
  - *Replacement Deletion*: Delete `template/.github/workflows/renimble.yml.jinja`, `.github/renimble.yml`, `.github/workflows/renimble.yml`, and purge all Renimble references from `README.md`, `template/README.md.jinja`, `AGENTS.md`, and `template/AGENTS.md.jinja`
  - *Holistic Verification*: Render fixtures, verify valid Dependabot YAML configuration across all flavors, run `just fixtures`, pass Three-Key Gate
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave`

### Phase 5: Systematic Review Remediation (Template Completeness, Dead Code Purge, and True Parity)
- [x] **Task 5.1: Template Payload Documentation & Workflows** (`@polyform-architect`)
  - *Strand*: `strand/template-payload-completion`
  - *Provider*: `template/tools/docgen.nim`, `template/docs/`, `template/.github/workflows/ci.yml.jinja`, `template/.github/workflows/docs.yml.jinja`, `template/.github/workflows/auto-tag.yml.jinja`, `template/.github/workflows/momus.yml.jinja`
  - *Consumer / Call-Site*: Downstream repository CI, docgen task, and GitHub Pages deployment
  - *Holistic Verification*: Render with `docs_engine: starlight`, verify `just docs-build` succeeds, and check generated workflows
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave`

- [x] **Task 5.2: Root Repository Cleansing & Polyform Storefront** (`@polyform-implementer`)
  - *Strand*: `strand/root-dead-code-purge-and-branding`
  - *Provider*: Root `README.md`, root `AGENTS.md`, root `justfile`
  - *Replacement Deletion*: Purge `project_name.nimble`, `src/project_name.nim`, `tests/test1.nim`, `mkdocs.yml`, `CLAUDE.md`, obsolete mkdocs docs
  - *Consumer / Call-Site*: Polyform repository storefront, contributor guide, canonical `just` surface
  - *Holistic Verification*: `git status` clean of legacy files, `just --list` clean of obsolete recipes, `pre-commit run --all-files` passes
  - *Weave*: `vine submit && vine audit approve --auditor polyform-auditor && vine weave`

- [x] **Task 5.3: Fixture Harness Hardening (Anti-Green-Mirage)** (`@polyform-auditor`)
  - *Strand*: `strand/fixture-harness-hardening`
  - *Provider*: `tests/test_fixtures.sh`
  - *Consumer / Call-Site*: Root `just test-fixtures` and GitHub Actions CI matrix
  - *Holistic Verification*: Render `pure_nim` with `docs_engine: starlight` and verify `just docs-build` succeeds and `.github/workflows/ci.yml` is validated
  - *Weave*: `vine submit && vine audit approve --auditor polyform-architect && vine weave`

---

## 5. Dynamic Progress Tracking
- Live status tracked via plan checkboxes (`- [ ]` to `- [x]`).
- Orchestrator broadcasts state transitions over Rhizo bus.
- Trunk merges are atomic fast-forwards executed exclusively via `vine weave`.

---

## 6. Emergent Design Addendum Protocol
If an implementer discovers an unforeseen constraint during coding:
1. **DO NOT silently diverge code from `design.md`**.
2. Draft `docs/addenda/addendum_<topic>.md` detailing problem, proposed deviation, and trade-offs.
3. Transmit notification via `rhizo send --to polyform-orchestrator --subject "Design Addendum: <topic>"`.
4. Orchestrator reviews, ratifies, updates `design.md` and `implementation_plan.md`, and approves before coding resumes.
