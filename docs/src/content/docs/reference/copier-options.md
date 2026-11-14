---
title: Copier Options Reference
description: Complete reference table of every configuration variable in Polyform's copier.yml, including types, defaults, choices, conditions, and generated file effects.
---

All template variables are defined in [`copier.yml`](https://github.com/axiomantic/polyform/blob/main/copier.yml) and persisted to `.copier-answers.yml` in generated repositories.

## 1. Project Identity & Metadata

| Variable | Type | Default | Validation / Constraint | Effect on Generated Project |
| :--- | :--- | :--- | :--- | :--- |
| **`project_name`** | `str` | `"my-project"` | `^[a-zA-Z0-9_ -]+$` | Human-readable project title in `README.md`, `docs/astro.config.mjs`, and `docs/src/content/docs/index.mdx`. |
| **`repo_name`** | `str` | `{{ project_name \| lower \| replace(' ', '-') \| replace('_', '-') }}` | `^[a-z0-9][a-z0-9-]+$` (kebab-case) | GitHub repository slug, Python distribution `name` in `pyproject.toml`, npm package name, and Starlight `base: '/<repo_name>'`. |
| **`package_name`** | `str` | `{{ repo_name \| replace('-', '_') }}` | `^[a-z][a-z0-9_]+$` (snake_case) | Nim module name (`src/<package_name>.nim`, `<package_name>.nimble`), Python import package (`src_py/<package_name>/`), and C header (`include/<package_name>.h`). |
| **`description`** | `str` | `"Production-grade project built with Axiomantic standards."` | Free text | Package description across `<package_name>.nimble`, `pyproject.toml`, `package.json`, and Starlight frontmatter. |
| **`author_name`** | `str` | `"Axiomantic Maintainers"` | Free text | Author attribution in `<package_name>.nimble`, `pyproject.toml`, `package.json`, and `LICENSE`. |
| **`author_email`** | `str` | `"maintainers@axiomantic.org"` | Free text | Author email in `pyproject.toml`. |
| **`github_owner`** | `str` | `"axiomantic"` | Free text | GitHub user/organization used in repository URLs, badges, and GitHub Pages `site: 'https://<github_owner>.github.io'`. |

## 2. Composable Language & Toolchain Facets

| Variable | Type | `when` Condition | Default | Effect on Generated Project |
| :--- | :--- | :--- | :--- | :--- |
| **`flavor`** | `str` | `false` (hidden preset) | `"custom"` | Optional preset (`pure_nim`, `nim_ts_wasm`, `nim_python_wheel`, `headerkit_binding`, `embedded_nim`) that seeds the default `has_*` booleans. |
| **`has_nim`** | `bool` | Always prompted | `true` (for standard flavors) | Includes `<package_name>.nimble`, `src/`, `nim.cfg`, `tests/config.nims`, `tests/test_<package_name>.nim`, and Nim CI jobs. |
| **`has_python`** | `bool` | Always prompted | `{{ flavor == 'nim_python_wheel' }}` | Includes `pyproject.toml`, `src_py/`, `tests_py/`, and Python CI/lint/test recipes. |
| **`has_typescript`** | `bool` | Always prompted | `{{ flavor == 'nim_ts_wasm' }}` | Includes `package.json`, `tsconfig.json`, `vitest.config.ts`, `ts/`, `tests/test_ts_bridge.ts`, and TypeScript CI jobs. |
| **`has_c_cpp`** | `bool` | Always prompted | `{{ flavor == 'headerkit_binding' }}` | Includes `include/<package_name>.h` and `CMakeLists.txt`. |
| **`has_embedded`** | `bool` | Always prompted | `{{ flavor == 'embedded_nim' }}` | Includes `embedded.cfg` (`--os:standalone --mm:arc`), CMake freestanding static library rules, and `embedded = true` in `headerkit.toml`. |

## 3. Interop Bridge Strategies & CI Matrix Flags

| Variable | Type | `when` Condition | Allowed Choices | Default | Effect on Generated Project |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`python_bridge_strategy`** | `str` | `has_nim and has_python` | `"naganim"`, `"ctypes_cabi"`, `"none"` | `"ctypes_cabi"` if `flavor == 'nim_python_wheel'` else `"naganim"` | Selects `naganim` (CPython `abi3`/`abi3t` + CFFI + thread-safe `NimMain` barrier), `ctypes_cabi` (`scikit-build-core` + `ctypes`), or `none` (`hatchling`). Includes `.github/workflows/cibuildwheel.yml` when `has_nim and has_python`. |
| **`python_freethreaded_ci`** | `bool` | `has_python` | `true`, `false` | `true` | Tests Python `["3.12", "3.13t", "3.14t"]` in `.github/workflows/ci.yml` and sets `CIBW_ENABLE: cpython-freethreaded` in `cibuildwheel.yml`. |
| **`nimony_ci`** | `bool` | `has_nim` | `true`, `false` | `true` | Adds `just check-nimony` recipe in `justfile` and Nimony / strict-defs check step in `.github/workflows/ci.yml`. |
| **`ts_bridge_strategy`** | `str` | `has_nim and has_typescript` | `"wasm"`, `"napi"`, `"none"` | `"wasm"` | Includes `scripts/compile_wasm.sh` and `just compile-wasm` when set to `"wasm"`. |
| **`c_binding_strategy`** | `str` | `has_nim and has_c_cpp` | `"headerkit"`, `"cmake_static"`, `"none"` | `"headerkit"` | Includes `headerkit.toml`, `scripts/generate_bindings.py`, `src/<package_name>/bindings.nim`, `src/<package_name>/dsl.nim`, `tests/test_tripwire.nim`, `tests/test_dsl.nim`, and `headerkit>=0.51.0` when set to `"headerkit"`. |

## 4. Documentation, AI Review & Licensing

| Variable | Type | `when` Condition | Allowed Choices | Default | Effect on Generated Project |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`docs_engine`** | `str` | Always prompted | `"starlight"`, `"none"` | `"starlight"` | Includes `docs/` (Astro Starlight), `tools/docgen.nim`, `.github/workflows/docs.yml`, and `just docs` / `just docs-build` when `"starlight"`. |
| **`enable_momus_review`** | `bool` | Always prompted | `true`, `false` | `true` | Includes `.github/workflows/momus.yml` and `.momus.yaml` for automated AI PR review. |
| **`momus_model`** | `str` | `enable_momus_review` | Model ID string | `"~anthropic/claude-sonnet-latest"` | Configures the LLM model identifier in `.momus.yaml`. |
| **`momus_base_url`** | `str` | `enable_momus_review` | URL string | `"https://openrouter.ai/api/v1"` | Configures the OpenAI-compatible API endpoint in `.momus.yaml`. |
| **`license`** | `str` | Always prompted | `"MIT"`, `"Apache-2.0"`, `"BSD-3-Clause"`, `"Unlicense"` | `"MIT"` | Renders `LICENSE` and license metadata across package manifests. |

## 5. Hardware Acceleration & Ephemeral GPU Runners

| Variable | Type | `when` Condition | Allowed Choices | Default | Effect on Generated Project |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`ci_gpu_runner`** | `str` | Always prompted | `"none"`, `"krun_apple_silicon"` | `"none"` | When set to `"krun_apple_silicon"`, renders `.github/workflows/gpu-ci.yml` targeting `runs-on: [self-hosted, linux, arm64, gpu]` powered by `gh-krun-runner` (`krunkit` + Virtio-GPU Venus + MoltenVK) **[Experimental / WIP]**. Eliminates expensive GitHub Actions macOS minutes (10x billing multiplier) and cloud GPU fees by running ephemeral microVMs with Metal/Vulkan compute locally. *NOTE: Requires running the host daemon on a local Apple Silicon Mac that must be booted for CI jobs to run.* Adds `just test-gpu` recipe to `justfile`. |
