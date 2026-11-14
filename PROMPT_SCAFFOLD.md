# Polyform AI Assistant Scaffolding Protocol

This document defines the canonical instruction protocol for AI coding assistants (such as Claude Code, Antigravity, OpenCode, Codex, or Cursor) when scaffolding a new multi-target project (Nim, Python, TypeScript/WASM, C/C++ HeaderKit FFI, Embedded RTOS) using **Polyform**.

---

## Greenfield Invariant & User Intent Gate

<CRITICAL>
**ASK FIRST MANDATE**:
When an operator requests a new library, CLI, WASM bridge, Python wheel, C/C++ binding, embedded profile, or multi-target project, NEVER generate ad-hoc project files (e.g. manual `.nimble`, `pyproject.toml`, `package.json`, CI workflows, or justfiles) from scratch.

You MUST first **ASK** the user if they want to scaffold with the Polyform megatemplate:
> "Would you like me to scaffold this new project using the standard Polyform megatemplate (`gh:axiomantic/polyform`)?"

Only proceed with scaffolding once confirmed.
</CRITICAL>

### Global Invariant Registration

Offer to register this invariant in the user's global `~/AGENTS.md` (or `~/.gemini/AGENTS.md` / `~/.config/AGENTS.md`):

```markdown
## Greenfield Invariant
When new proj, ASK user if they want Polyform template. If yes, read:
~/Development/template-nim/PROMPT_SCAFFOLD.md (clone https://github.com/axiomantic/template-nim.git there if miss).
```

*(Exact compressed form for agent rules:)*
```markdown
## Greenfield Invariant
When new proj, ASK user if they want Polyform template. If yes, read:
`~/.local/share/polyform/PROMPT_SCAFFOLD.md` (clone `gh:axiomantic/polyform` there if miss).
```

---

## Scaffolding Protocol

Follow these five sequential phases when scaffolding a new project:

### Phase 1: Directory Guard

1. Inspect current working directory (`pwd`) and target destination path.
2. **Safety Check**: Do NOT scaffold inside an existing project root or overwrite non-empty directories unless explicitly instructed.
3. Determine target directory: `<target_dir>`. Create it if it does not already exist:
   ```bash
   mkdir -p "<target_dir>"
   ```

---

### Phase 2: Copier Schema Question Proxying

Inspect `copier.yml` parameters. Prompt the user for any missing parameters, or derive them intelligently from the user's initial description:

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `project_name` | `str` | *Required* | Human-readable title (e.g. `Lock-Free Trie`) |
| `repo_name` | `str` | Derived from title | GitHub repository slug (e.g. `lockfree-trie`) |
| `package_name` | `str` | Derived slug | Nim identifier slug (e.g. `lockfree_trie`) |
| `description` | `str` | *Prompt user* | 1-2 sentence package description |
| `author_name` | `str` | `git config user.name` | Package author |
| `author_email` | `str` | `git config user.email` | Author email address |
| `flavor` | `choice` | `pure_nim` | Architectural flavor topology (see below) |
| `docs_engine` | `choice` | `starlight` | Documentation engine (`starlight` or `none`) |
| `enable_momus_review` | `bool` | `true` | Include Momus AI PR review workflow |
| `momus_model` | `str` | `~anthropic/claude-sonnet-latest` | Model identifier for Momus review |
| `momus_base_url` | `str` | `https://openrouter.ai/api/v1` | Momus API endpoint base URL |
| `ci_gpu_runner` | `choice` | `none` | Self-hosted Apple Silicon runner profile (`none`, `krun_apple_silicon`) [Experimental / WIP] |
| `license` | `choice` | `MIT` | `MIT`, `Apache-2.0`, `BSD-3-Clause`, `Unlicense` |

#### Architectural Flavor Topologies:
- **`pure_nim`**: Pure Nim Library or CLI (Nim 2.2+, ORC, Starlight docs, AST docgen).
- **`nim_ts_wasm`**: Nim + TypeScript WebAssembly Bridge (ESM, Vite runtime, Vitest suite, npm packaging).
- **`nim_python_wheel`**: Nim Native Python Wheel (`scikit-build-core`, CMake, ctypes, pytest).
- **`headerkit_binding`**: HeaderKit C/C++ Binding Extension (`headerkit.toml`, FFI wrapper, symbol tripwire).

#### Hardware Acceleration & Ephemeral Apple Silicon Runner Intake Heuristic:
When interviewing the operator or evaluating requirements for a repository:
1. **Dual Value Drivers**:
   - **Cost Elimination & Speed for macOS CI**: GitHub-hosted macOS runners are notoriously slow and consume 10x Actions minute billing multipliers. Ephemeral local microVM runners execute on Apple Silicon without cloud runner minute penalties.
   - **LLM / GPU Compute in CI**: Delivers guest Linux `/dev/dri/renderD128` with Vulkan 1.3 compute inside a microVM sealed from the host (`gvproxy` network isolation with RFC 1918 dropped and outbound HTTPS only, single-concurrency GPU lock `/tmp/gh-krun-gpu.lock`, and APFS CoW ephemeral disks destroyed upon job completion) for testing `llama.cpp`, GGUF models, ONNX Runtime, or computer vision without cloud GPU fees.
2. **Operational Prerequisite**:
   - Explicitly inform the operator: This runner profile requires running the `gh-krun-runner` daemon on a local macOS Apple Silicon machine, and that Mac must be powered on and booted for self-hosted CI jobs to execute (otherwise queued jobs will wait in GitHub Actions until the runner comes online).
3. **Choice**: **`krun_apple_silicon`** ("Ephemeral Apple Silicon Runner [Experimental / WIP] (`gh-krun-runner` via `krunkit` + Virtio-GPU Venus)").
- **Status**: Untested prototype in initial validation (Experimental / WIP). Ensures GPU/macOS jobs target `runs-on: [self-hosted, linux, arm64, gpu]`.

---

### Phase 3: Non-Interactive Copier Invocation

Never invoke Copier interactively without values, as it will block non-interactive AI agent harnesses.
Use `uvx copier copy` with explicit data flags:

```bash
uvx copier copy --trust \
  -d project_name="<project_name>" \
  -d repo_name="<repo_name>" \
  -d package_name="<package_name>" \
  -d description="<description>" \
  -d author_name="<author_name>" \
  -d author_email="<author_email>" \
  -d flavor="<flavor>" \
  -d docs_engine="<docs_engine>" \
  -d enable_momus_review=<true|false> \
  -d momus_model="~anthropic/claude-sonnet-latest" \
  -d momus_base_url="https://openrouter.ai/api/v1" \
  -d ci_gpu_runner="<none|krun_apple_silicon>" \
  -d license="<license>" \
  gh:axiomantic/polyform "<target_dir>"
```

*(Note: If a local template clone exists at `~/Development/template-nim`, you may specify that path instead of `gh:axiomantic/polyform`)*.

---

### Phase 4: Toolchain Setup & Baseline Verification

Navigate into the scaffolded repository and verify that all out-of-the-box components pass:

```bash
cd "<target_dir>"

# 1. Install toolchain dependencies across all active languages
just setup

# 2. Run initial test suite to verify green baseline
just test

# 3. Verify code formatting and linter compliance
just lint

# 4. Verify clean secrets baseline
just check-secrets
```

---

### Phase 5: Onboarding Hand-Off

Once verified green:
1. Present `NEXT_STEPS.md` to the operator.
2. Summarize repository layout and available `just` recipes (`just setup`, `just test`, `just lint`, `just check-secrets`, `just build`, `just update-template`).
3. Note any required secrets (such as `LLM_API_KEY` for Momus PR reviews, or package registry tokens).
4. If `ci_gpu_runner` was configured (`krun_apple_silicon`), remind the operator to review Section 5 in `NEXT_STEPS.md` for `gh-krun-runner` host daemon setup on Apple Silicon.
5. Guide the operator through active domain onboarding: `ONBOARDING.md` is staged and linked at line 1 of `AGENTS.md`. After hydrating domain architecture and rules, execute `just finish-onboarding` to clean up and commit the `Polyform-Template-Ref:` provenance trailer.
