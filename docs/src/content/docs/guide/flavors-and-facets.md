---
title: Flavors & Composable Facets
description: Detailed guide to Polyform's 4 architectural flavor presets, composable language facets, native interop bridge strategies, and CI hardening flags.
---

Polyform supports both **architectural flavor presets** (`flavor`) and fine-grained **composable boolean facets** (`has_nim`, `has_python`, `has_typescript`, `has_c_cpp`, `has_embedded`).

## The 4 Canonical Flavor Presets

While `flavor` is a hidden preset variable (`when: false`, `default: "custom"`), passing `-d flavor=<preset>` sets the default boolean facets automatically:

| Flavor Preset | Default Facets Enabled | Default Bridge Strategy | Primary Use Case |
| :--- | :--- | :--- | :--- |
| **`pure_nim`** | `has_nim=true` | None | Pure Nim 2.2+ libraries and CLI binaries with `nimble`, `nph`, Nimony CI, and Astro Starlight docs. |
| **`nim_ts_wasm`** | `has_nim=true`, `has_typescript=true` | `ts_bridge_strategy="wasm"` | Nim compiled to WebAssembly (`scripts/compile_wasm.sh`) consumed by TypeScript/ESM with Vitest tests. |
| **`nim_python_wheel`** | `has_nim=true`, `has_python=true` | `python_bridge_strategy="ctypes_cabi"` (or `"naganim"`) | Native Python wheels built via `scikit-build-core` + `CMakeLists.txt` + `cibuildwheel`. |
| **`headerkit_binding`** | `has_nim=true`, `has_c_cpp=true` | `c_binding_strategy="headerkit"` | Automated C/C++ header-to-Nim FFI bindings using `headerkit>=0.51.0` (`headerkit.toml`) + Tripwire symbol verification + idiomatic `dsl.nim` overlay. |

---

## Composable Language & Target Facets

You can combine any subset of the five core boolean facets:

### 1. `has_nim` (Nim Toolchain)
Scaffolds `<package_name>.nimble`, `src/<package_name>.nim`, `nim.cfg`, and `tests/test_<package_name>.nim`.
- **Formatting**: Enforces `nph` formatting in `just lint-nim` and `just fmt`.
- **`nimony_ci`** (`default: true`): Adds a `just check-nimony` recipe and CI step that runs `nimony check src/<package_name>.nim` (or falls back to `nim check --experimental:strictFuncs --experimental:strictDefs` when `nimony` is not installed).

### 2. `has_python` (Python Toolchain)
Scaffolds `pyproject.toml`, `src_py/<package_name>/__init__.py`, and `tests_py/test_<package_name>.py`.
- **`python_bridge_strategy`** (active when `has_nim and has_python`):
  - **`naganim`** *(default when `flavor != 'nim_python_wheel'`)*: Bidirectional CPython `abi3`/`abi3t` + CFFI + lock-free `asyncio` bridge (`elijahr/naganim`). Includes a 3-state thread-safe atomic spin-wait barrier (`gNimMainState`) around `NimMain()` in `src/<package_name>.nim` so concurrent free-threaded Python threads safely initialize the Nim runtime once.
  - **`ctypes_cabi`**: Compiles Nim into a shared library via `scikit-build-core` and `CMakeLists.txt`, loading exported `{.exportc, dynlib.}` C-ABI procedures via Python `ctypes`.
  - **`none`**: Independent parallel Python package built with `hatchling`.
- **`python_freethreaded_ci`** (`default: true`): Expands the GitHub Actions Python test matrix to `["3.12", "3.13t", "3.14t"]` and enables `CIBW_ENABLE: cpython-freethreaded` in `.github/workflows/cibuildwheel.yml` (`cibuildwheel==2.23.3`) for PEP 703 `nogil` wheels.

### 3. `has_typescript` (TypeScript & WebAssembly Toolchain)
Scaffolds `package.json`, `tsconfig.json`, `vitest.config.ts`, `ts/index.ts`, and `tests/test_ts_bridge.ts`.
- **`ts_bridge_strategy`** (active when `has_nim and has_typescript`):
  - **`wasm`** *(default)*: Generates `scripts/compile_wasm.sh` and compiles Nim to WebAssembly for browser and Node.js consumption.
  - **`napi`**: Configures Node.js native N-API addon bindings.
  - **`none`**: Independent parallel TypeScript package.

### 4. `has_c_cpp` (C/C++ Foreign Interop & HeaderKit FFI)
Scaffolds `include/<package_name>.h` and `CMakeLists.txt`.
- **`c_binding_strategy`** (active when `has_nim and has_c_cpp`):
  - **`headerkit`** *(default)*: Scaffolds declarative `headerkit.toml` (`backend = "libclang"`, `[[targets]]` with `writer = "nim"`, `output = "src/<package_name>/bindings.nim"`, `strip_include_prefixes = ["include"]`), `scripts/generate_bindings.py`, `src/<package_name>/bindings.nim`, `src/<package_name>/dsl.nim`, `tests/test_tripwire.nim`, and `tests/test_dsl.nim` using `headerkit>=0.51.0`.
  - **`cmake_static`**: CMake static/shared library linkage without HeaderKit codegen.
  - **`none`**: Direct foreign header compilation.

### 5. `has_embedded` (Freestanding RTOS & Bare-Metal Profile)
Scaffolds `embedded.cfg` with standalone deterministic memory management (`--os:standalone --mm:arc --exceptions:goto --threads:off -d:useMalloc --header`), CMake freestanding C translation and static library targets in `CMakeLists.txt`, and sets `options = { embedded = true, strip_include_prefixes = ["include"] }` under `[[targets]]` in `headerkit.toml` for FreeRTOS, Zephyr (`west`), and bare-metal firmware targets.

---

## Hardware Acceleration: Ephemeral Apple Silicon GPU Runner (`gh-krun-runner`) [Experimental / WIP]

> **Status: Experimental / WIP** — This runner profile is an active prototype currently undergoing initial validation.

Repositories requiring machine learning, LLM inference (e.g. `llama.cpp`, GGUF models), ONNX Runtime Vulkan execution, or seeking to eliminate expensive GitHub-hosted macOS CI minutes can configure the optional **`ci_gpu_runner: "krun_apple_silicon"`** profile.

### Core Value Drivers & Architectural Invariants

```
                             +------------------------------------------+
                             |        macOS Host (Apple Silicon)        |
                             |  +--------------------+                  |
                             |  | Host Orchestrator  |<--- GitHub JIT   |
                             |  | (gh-krun-runner)   |     API Tokens   |
                             |  +---------+----------+                  |
                             |            |                             |
      Single-Concurrency Lock|            | [APFS CoW cp -c]            |
      (/tmp/gh-krun-gpu.lock)|            v                             |
                             |    +---------------+                     |
                             |    | Linux MicroVM |                     |
                             |    | (krunkit)     |                     |
                             |    +-------+-------+                     |
                             |            |                             |
    +------------------------+------------+-------------+               |
    |                        |                          |               |
    v                        v                          v               v
[Virtio-GPU Venus]     [Virtio-Net]               [Virtio-FS]      [Virtio-Blk]
virglrenderer +        gvproxy                    Host /models     Ephemeral CoW
MoltenVK (Metal)       (Outbound HTTPS Only)      (Read-Only)      disk.raw
    |                        |                          |               |
+---|------------------------|--------------------------|---------------|---+
| GUEST: /dev/dri/renderD128 eth0 (RFC 1918 Blocked)    /models         /   |
| Vulkan 1.3 Compute         Outbound HTTPS Only        GGUF Weights    Wiped
+---------------------------------------------------------------------------+
```

1. **Dual Value Drivers**:
   - **Eliminate macOS CI Runner Surcharges**: GitHub-hosted macOS runners are noticeably slow and incur a 10x per-minute billing multiplier. Ephemeral local microVM runners execute on Apple Silicon without cloud minute fees.
   - **Zero Cloud GPU Surcharges**: Provides local Metal-backed Vulkan 1.3 GPU execution for ML/LLM workloads (`llama.cpp`, GGUF models, ONNX Runtime).
2. **Operational Prerequisite**:
   - The host macOS Apple Silicon machine **must be booted and running** with the `gh-krun-runner` daemon active for self-hosted CI jobs to execute. Queued jobs will wait in GitHub Actions until the runner comes online.
3. **Strict `runs-on` Targeting**: Non-GPU jobs (linting, unit tests, secrets scan) MUST remain on standard GitHub-hosted runners (`ubuntu-latest`). Only GPU/macOS-dependent jobs target `runs-on: [self-hosted, linux, arm64, gpu]`.
4. **Sealed MicroVM Sandbox**: Built on `krunkit` (Hypervisor.framework) + Virtio-GPU Venus (`virglrenderer` + `MoltenVK`) delivering guest Linux `/dev/dri/renderD128` with Vulkan 1.3 compute.
5. **Network & Storage Isolation**: `gvproxy` blocks RFC 1918, host loopback, and LAN traffic, permitting outbound HTTPS only. Zero host root filesystem access is permitted; optional host model weights are mounted strictly read-only (`ro`).
6. **Ephemeral JIT Runners & APFS CoW**: Base disk images are cloned in <50ms with `cp -c` and destroyed along with transient GitHub JIT runner tokens immediately upon job termination.
7. **Host Single-Concurrency GPU Locking**: Host daemon serializes microVM launches using `/tmp/gh-krun-gpu.lock` to prevent Apple Silicon unified memory exhaustion.
8. **Downstream Dev Surface**: Adds `just test-gpu` to the generated `justfile`.
