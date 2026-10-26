# Polyform Systematic Adversarial Dialectical Pump Review
**Audit Scope**: Entire Polyform Megatemplate Codebase, Payloads, Fixtures, and Workflows  
**Conducted By**: Swarm Dialectical Triad (`@polyform-auditor`, `@polyform-architect`, `@polyform-implementer`, `@polyform-orchestrator`)  
**Standard**: Five-Pillar Closed-Circuit Integrity, Zero-Shelfware Policy, Anti-Green-Mirage Protocol  
**Date**: 2026-10-24  
**Audit Finding Summary**: 2 CRITICAL, 2 HIGH, 1 MEDIUM (Remediation Plan Formulated)  

---

## 1. Executive Summary

Following the completion and trunk weaving of Phases 1 through 4 (Tasks 1.1, 1.2, 2.1, 2.2, 2.3, 3.1, 3.2, 4.1), a systematic adversarial audit was executed across the entire repository under the strict **Presumption of Guilt**.

Rather than relying on happy-path test runs, the audit executed empirical probes, inspecting both the template payload (`template/`), the root repository (`.`), and rendered downstream fixtures across all permutations.

This deep forensic review revealed **2 Critical defects, 2 High defects, and 1 Medium defect**, explaining why downstream documentation generation fails and uncovering residual legacy carcasses from the original `template-nim` repository.

---

## 2. Complete Defect Inventory

| Defect ID | Severity | Pillar | Target / Location | Empirical Proof / Description |
|---|---|---|---|---|
| **CRIT-01** | CRITICAL | Pillar 1 & 2 (Shelfware / Integration) | `template/tools/docgen.nim` & `template/docs/` | **Missing Docs Payload**: `template/` omits `docs/` and `tools/docgen.nim`. Downstream repos rendered with default `docs_engine: starlight` crash when running `just docs` with `Error: cannot open 'tools/'` and `FAILED: nim c -r tools/docgen.nim`. |
| **CRIT-02** | CRITICAL | Pillar 1 (Closed-Circuit Diff) | `template/.github/workflows/` | **Missing Downstream Workflows**: `template/.github/workflows/` only contains `dependabot-verify.yml` and `cibuildwheel.yml`. Downstream projects receive NO `ci.yml`, NO `docs.yml`, NO `auto-tag.yml`, and NO `momus.yml`. |
| **HIGH-01** | HIGH | Pillar 5 (Green Mirage) | `tests/test_fixtures.sh:63` | **Fixture Docs Engine Bypass**: `test_fixtures.sh` hardcodes `-d docs_engine="none"` across all 4 flavors, preventing the test harness from exercising or detecting the failure of `docs` and `tools/docgen.nim`. |
| **HIGH-02** | HIGH | Pillar 4 (Dead Code Purge) | Root repository root (`.`) | **Legacy Carcasses**: Ancient `template-nim` files remain in repo root: `project_name.nimble`, `src/project_name.nim`, `tests/test1.nim`, `mkdocs.yml`, `CLAUDE.md`, and ancient unbranded `README.md` and `AGENTS.md`. |
| **MED-01** | MEDIUM | Pillar 5 (Assertion Rigor) | `template/tests/test_{{ package_name }}.nim.jinja` | **Incomplete Test Coverage**: Downstream unit tests only check `hello()` and version string; `add(a, b)` and boundary error assertions are omitted. |

---

## 3. Forensic Evidence & Reproductions

### Proof of CRIT-01 (Documentation Generation Crash)
- **Reproduction**:
  ```bash
  uvx copier copy --vcs-ref=HEAD --trust --defaults -d project_name="Test Project" -d flavor="pure_nim" -d docs_engine="starlight" . /tmp/test-review
  cd /tmp/test-review && just docs
  ```
- **Error Output**:
  ```text
  Error: cannot open 'tools/'
  Error: unhandled exception: FAILED: nim c -r tools/docgen.nim [OSError]
  error: recipe `docs` failed on line 28 with exit code 1
  ```
- **Root Cause**: `copier.yml` configures `_subdirectory: template`. Copier exclusively copies files from inside `template/`. Because `tools/` and `docs/` were maintained in the root repo rather than inside `template/`, downstream projects never received them.

### Proof of CRIT-02 (Missing CI Workflows in Downstream Projects)
- **Reproduction**:
  Inspect `/tmp/test-review/.github/workflows/`:
  ```bash
  ls -la /tmp/test-review/.github/workflows/
  ```
- **Observed**:
  Only `dependabot-verify.yml` exists. Downstream repos have no GitHub Actions workflow to run their tests on pull requests or pushes, no release tagging, and no docs deployment.

### Proof of HIGH-01 (Green Mirage in Root Harness)
- **Line Citation**: `tests/test_fixtures.sh:63`
  ```bash
  -d docs_engine="none"
  ```
- The test harness intentionally bypassed documentation generation to pass quickly, masking the absence of `template/docs` and `template/tools`.

### Proof of HIGH-02 (Root Dead Code Carcasses)
- The root of `axiomantic/polyform` still contains:
  - `project_name.nimble` (smoke tests dummy project_name)
  - `src/project_name.nim`
  - `tests/test1.nim`
  - `mkdocs.yml` (dead MkDocs format)
  - `README.md` (states `# project_name` and gives instructions on how to use `template-cleanup.yml`)

---

## 4. Remediation Plan (Phase 5)

### Task 5.1: Template Payload Documentation & Workflows (`@polyform-architect`)
1. Create `template/tools/docgen.nim` (generic AST doc extractor).
2. Create `template/docs/` with templated Astro Starlight portal:
   - `astro.config.mjs.jinja` (`title: "{{ project_name }}"`, `base: "/{{ repo_name }}"`, `href: "https://github.com/{{ github_owner }}/{{ repo_name }}"`).
   - `package.json.jinja` (Astro, `@astrojs/starlight`, Starlight plugins).
   - `src/content/docs/index.mdx.jinja` and `src/content.config.ts`.
3. Create `template/.github/workflows/ci.yml.jinja` supporting matrix test runner across all flavors.
4. Create `template/.github/workflows/docs.yml.jinja` (build & deploy Starlight docs to GitHub Pages).
5. Create `template/.github/workflows/auto-tag.yml.jinja` (version tag automation).
6. Create `template/.github/workflows/momus.yml.jinja` (AI PR review).

### Task 5.2: Root Repository Cleansing & Polyform Storefront (`@polyform-implementer`)
1. **Aggressive Replacement Purge**:
   - Delete `project_name.nimble`, `src/project_name.nim`, `tests/test1.nim`.
   - Delete `mkdocs.yml`, `docs/api-reference.md`, `docs/index.md`, `CLAUDE.md`.
2. Rewrite root `README.md` into the official **Polyform** showcase:
   - Highlighting the 4 flavors (`pure_nim`, `nim_ts_wasm`, `nim_python_wheel`, `headerkit_binding`).
   - CLI usage (`uvx copier copy`).
   - GitHub Web UI "Use this template" usage.
   - Canonical `just` commands (`just fixtures`, `just test-fixtures`).
   - Continuous update instructions (`uvx copier update`).
3. Rewrite root `AGENTS.md` and root `justfile` to remove obsolete recipes (`rename`, `mkdocs`).

### Task 5.3: Fixture Harness Hardening (Anti-Green-Mirage) (`@polyform-auditor`)
1. Update `tests/test_fixtures.sh`:
   - Test at least one flavor (`pure_nim`) with `-d docs_engine="starlight"`.
   - Verify that `just docs-build` executes and generates static HTML.
   - Verify that `.github/workflows/ci.yml` is present in rendered fixtures.
2. Run full matrix fixtures to ensure 100% pass rate.
