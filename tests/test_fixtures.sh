#!/usr/bin/env bash
# tests/test_fixtures.sh - Polyform Composable Matrix Fixture Verification Harness
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export PATH="${HOME}/.nimble/bin:${PATH}"

TARGET_FIXTURE="${1:-all}"
MODE="${2:-all}" # all | test | lint

# Map legacy flavor names to composable fixture targets
case "${TARGET_FIXTURE}" in
  pure_nim)
    TARGET_FIXTURE="fixture-pure-nim"
    ;;
  nim_ts_wasm)
    TARGET_FIXTURE="fixture-nim-ts"
    ;;
  nim_python_wheel)
    TARGET_FIXTURE="fixture-nim-py"
    ;;
  headerkit_binding)
    TARGET_FIXTURE="fixture-nim-c"
    ;;
esac

if [[ "${TARGET_FIXTURE}" == "all" ]]; then
  FIXTURES=(
    "fixture-pure-nim"
    "fixture-pure-py"
    "fixture-pure-ts"
    "fixture-nim-ts"
    "fixture-nim-py"
    "fixture-nim-c"
  )
else
  FIXTURES=("${TARGET_FIXTURE}")
fi

FIXTURE_DIR="$(mktemp -d /tmp/polyform-fixtures-XXXXXX)"
trap 'rm -rf "${FIXTURE_DIR}"' EXIT

echo "=== [POLYFORM ROOT HARNESS] Starting Composable Fixture Matrix Verification ==="
echo "Target Fixtures: ${FIXTURES[*]}"
echo "Mode           : ${MODE}"
echo "Repository Root: ${REPO_ROOT}"
echo "Staging Root   : ${FIXTURE_DIR}"

for FIXTURE in "${FIXTURES[@]}"; do
  echo ""
  echo "======================================================================"
  echo ">>> [FIXTURE] Rendering & Verifying: ${FIXTURE}"
  echo "======================================================================"

  DEST="${FIXTURE_DIR}/${FIXTURE}"
  REPO_SLUG="${FIXTURE}"
  PKG_SLUG="${FIXTURE//-/_}"

  # Default facet flags
  HAS_NIM=false
  HAS_PYTHON=false
  HAS_TYPESCRIPT=false
  HAS_C_CPP=false
  DOCS_ENGINE="none"
  TS_BRIDGE="none"
  PYTHON_BRIDGE="none"
  C_BINDING="none"

  case "${FIXTURE}" in
    fixture-pure-nim)
      HAS_NIM=true
      DOCS_ENGINE="starlight"
      ;;
    fixture-pure-py)
      HAS_PYTHON=true
      ;;
    fixture-pure-ts)
      HAS_TYPESCRIPT=true
      ;;
    fixture-nim-ts)
      HAS_NIM=true
      HAS_TYPESCRIPT=true
      TS_BRIDGE="wasm"
      ;;
    fixture-nim-py)
      HAS_NIM=true
      HAS_PYTHON=true
      PYTHON_BRIDGE="ctypes_cabi"
      ;;
    fixture-nim-c)
      HAS_NIM=true
      HAS_C_CPP=true
      C_BINDING="headerkit"
      ;;
    *)
      echo "ERROR: Unknown fixture profile: ${FIXTURE}" >&2
      exit 1
      ;;
  esac

  COPIER_ARGS=(
    --vcs-ref=HEAD --trust --defaults
    -d project_name="Fixture ${FIXTURE}"
    -d repo_name="${REPO_SLUG}"
    -d package_name="${PKG_SLUG}"
    -d has_nim="${HAS_NIM}"
    -d has_python="${HAS_PYTHON}"
    -d has_typescript="${HAS_TYPESCRIPT}"
    -d has_c_cpp="${HAS_C_CPP}"
    -d docs_engine="${DOCS_ENGINE}"
  )

  if [[ "${HAS_TYPESCRIPT}" == "true" && "${HAS_NIM}" == "true" ]]; then
    COPIER_ARGS+=(-d ts_bridge_strategy="${TS_BRIDGE}")
  fi
  if [[ "${HAS_PYTHON}" == "true" && "${HAS_NIM}" == "true" ]]; then
    COPIER_ARGS+=(-d python_bridge_strategy="${PYTHON_BRIDGE}")
  fi
  if [[ "${HAS_C_CPP}" == "true" && "${HAS_NIM}" == "true" ]]; then
    COPIER_ARGS+=(-d c_binding_strategy="${C_BINDING}")
  fi

  uvx copier copy "${COPIER_ARGS[@]}" "${REPO_ROOT}" "${DEST}"

  echo ">>> [VERIFY] Checking universal configuration files and hooks..."
  test -f "${DEST}/.copier-answers.yml"
  test -f "${DEST}/.github/workflows/ci.yml"
  test -f "${DEST}/NEXT_STEPS.md"
  test -f "${DEST}/.momus.yaml"
  test -f "${DEST}/.github/renovate.json"
  test -f "${DEST}/.github/dependabot.yml"

  if grep -q 'package-ecosystem: "nimble"' "${DEST}/.github/dependabot.yml"; then
    echo "ERROR: dependabot.yml must not contain unsupported nimble ecosystem" >&2
    exit 1
  fi

  grep -q "update-template:" "${DEST}/justfile"
  grep -q "check-secrets:" "${DEST}/justfile"
  grep -q "check-secrets:" "${REPO_ROOT}/justfile"
  grep -q "https://github.com/gitleaks/gitleaks" "${DEST}/.pre-commit-config.yaml"
  grep -q "rev: v8.24.0" "${DEST}/.pre-commit-config.yaml"
  grep -q "secrets-scan:" "${DEST}/.github/workflows/ci.yml"
  grep -q "gitleaks detect --verbose" "${DEST}/.github/workflows/ci.yml"
  grep -q "model: ~anthropic/claude-sonnet-latest" "${DEST}/.github/workflows/momus.yml"
  grep -q "base_url: https://openrouter.ai/api/v1" "${DEST}/.github/workflows/momus.yml"
  grep -q "only_collaborators: true" "${DEST}/.github/workflows/momus.yml"
  grep -q "environment: code-review" "${DEST}/.github/workflows/momus.yml"
  grep -q "LLM_API_KEY:" "${DEST}/.github/workflows/momus.yml"
  grep -q "permissions: {}" "${DEST}/.github/workflows/momus.yml"
  grep -q "github.event.sender.type != 'Bot'" "${DEST}/.github/workflows/momus.yml"
  grep -q "~anthropic/claude-sonnet-latest" "${DEST}/.momus.yaml"
  grep -q "https://openrouter.ai/api/v1" "${DEST}/.momus.yaml"
  grep -q "import? 'justfile.local'" "${DEST}/justfile"

  # Test local justfile extension hook
  echo "test-hook:" > "${DEST}/justfile.local"
  echo "    @echo 'local-hook-active'" >> "${DEST}/justfile.local"
  LOCAL_HOOK_OUT=$(cd "${DEST}" && just test-hook)
  rm -f "${DEST}/justfile.local"
  if [[ "${LOCAL_HOOK_OUT}" != "local-hook-active" ]]; then
    echo "ERROR: justfile.local extension hook failed to execute in ${FIXTURE}" >&2
    exit 1
  fi

  # Auto-tag workflow target checks
  test -f "${DEST}/.github/workflows/auto-tag.yml"
  if [[ "${HAS_NIM}" == "true" ]]; then
    grep -q "${PKG_SLUG}.nimble" "${DEST}/.github/workflows/auto-tag.yml"
  elif [[ "${HAS_PYTHON}" == "true" ]]; then
    grep -q "pyproject.toml" "${DEST}/.github/workflows/auto-tag.yml"
  elif [[ "${HAS_TYPESCRIPT}" == "true" ]]; then
    grep -q "package.json" "${DEST}/.github/workflows/auto-tag.yml"
  fi

  echo ">>> [VERIFY] Negative controls & anti-green-mirage assertions..."
  # Strict negative control: pure python and pure typescript must have ZERO Nim artifacts
  if [[ "${HAS_NIM}" == "false" ]]; then
    test ! -f "${DEST}/${PKG_SLUG}.nimble"
    test ! -f "${DEST}/nim.cfg"
    test ! -d "${DEST}/src"
    NIM_LEAK=$(find "${DEST}" -maxdepth 3 \( -name "*.nim" -o -name "*.nimble" \) | grep -v ".git" || true)
    if [[ -n "${NIM_LEAK}" ]]; then
      echo "ERROR: Found leaked Nim files in non-Nim fixture ${FIXTURE}:" >&2
      echo "${NIM_LEAK}" >&2
      exit 1
    fi
  else
    test -f "${DEST}/${PKG_SLUG}.nimble"
    test -f "${DEST}/nim.cfg"
    test -d "${DEST}/src"
    test -f "${DEST}/tests/test_${PKG_SLUG}.nim"
  fi

  # Negative control: non-python fixtures must not have Python artifacts
  if [[ "${HAS_PYTHON}" == "false" ]]; then
    test ! -f "${DEST}/pyproject.toml"
    test ! -d "${DEST}/src_py"
    test ! -d "${DEST}/tests_py"
  else
    test -f "${DEST}/pyproject.toml"
    test -d "${DEST}/src_py"
    test -d "${DEST}/tests_py"
  fi

  # Negative control: non-typescript fixtures must not have root TS package.json
  if [[ "${HAS_TYPESCRIPT}" == "false" ]]; then
    test ! -f "${DEST}/package.json"
    test ! -f "${DEST}/tsconfig.json"
    test ! -d "${DEST}/ts"
  else
    test -f "${DEST}/package.json"
    test -f "${DEST}/tsconfig.json"
    test -d "${DEST}/ts"
  fi

  # Negative control: non-C/C++ fixtures must not have include/
  if [[ "${HAS_C_CPP}" == "false" ]]; then
    test ! -d "${DEST}/include"
    test ! -f "${DEST}/headerkit.toml"
  else
    test -d "${DEST}/include"
    if [[ "${C_BINDING}" == "headerkit" ]]; then
      test -f "${DEST}/headerkit.toml"
      test -f "${DEST}/scripts/generate_bindings.py"
      test -f "${DEST}/tests/test_tripwire.nim"
    fi
  fi

  # Negative control for Momus review exclusion
  if [[ "${FIXTURE}" == "fixture-pure-nim" ]]; then
    echo ">>> [VERIFY] Negative control: verifying momus exclusion when enable_momus_review=false..."
    MOMUS_NEG_DEST="${FIXTURE_DIR}/momus_neg_test"
    uvx copier copy --vcs-ref=HEAD --trust --defaults \
      -d project_name="Momus Neg Test" \
      -d repo_name="momus-neg-test" \
      -d package_name="momus_neg_test" \
      -d has_nim=true \
      -d has_python=false \
      -d has_typescript=false \
      -d has_c_cpp=false \
      -d docs_engine="none" \
      -d enable_momus_review=false \
      "${REPO_ROOT}" "${MOMUS_NEG_DEST}"
    test ! -f "${MOMUS_NEG_DEST}/.momus.yaml"
    test ! -f "${MOMUS_NEG_DEST}/.github/workflows/momus.yml"
    rm -rf "${MOMUS_NEG_DEST}"
    echo ">>> [VERIFY] Negative control passed: .momus.yaml and momus.yml successfully excluded."
  fi

  echo ">>> [SETUP] Installing required toolchain dependencies for ${FIXTURE}..."
  if [[ "${HAS_TYPESCRIPT}" == "true" ]]; then
    (cd "${DEST}" && npm install --no-audit --no-fund)
  fi
  if [[ "${DOCS_ENGINE}" == "starlight" ]]; then
    (cd "${DEST}/docs" && npm install --no-audit --no-fund)
  fi

  # LINT VERIFICATION
  if [[ "${MODE}" == "all" || "${MODE}" == "lint" ]]; then
    echo ">>> [LINT] Running linters for ${FIXTURE}..."
    if [[ "${HAS_NIM}" == "true" ]]; then
      (cd "${DEST}" && nph --check .)
      (cd "${DEST}" && nimble check)
    fi
    if [[ "${HAS_TYPESCRIPT}" == "true" ]]; then
      (cd "${DEST}" && npx tsc --noEmit)
    fi
    if [[ "${HAS_PYTHON}" == "true" ]]; then
      (cd "${DEST}" && uv run --with ruff ruff check .)
    fi
    echo ">>> [LINT] ${FIXTURE} linters passed cleanly."
  fi

  # TEST VERIFICATION
  if [[ "${MODE}" == "all" || "${MODE}" == "test" ]]; then
    echo ">>> [TEST] Running test suites for ${FIXTURE}..."
    if [[ "${HAS_NIM}" == "true" ]]; then
      (cd "${DEST}" && nimble test)
    fi
    if [[ "${HAS_TYPESCRIPT}" == "true" && "${TS_BRIDGE}" == "wasm" ]]; then
      echo ">>> [BUILD] Compiling WASM module..."
      (cd "${DEST}" && bash scripts/compile_wasm.sh)
      test -f "${DEST}/dist/${PKG_SLUG}.wasm"
      (cd "${DEST}" && npx vitest run)
    elif [[ "${HAS_TYPESCRIPT}" == "true" ]]; then
      (cd "${DEST}" && npx vitest run)
    fi
    if [[ "${HAS_PYTHON}" == "true" ]]; then
      (cd "${DEST}" && uv run --with pytest pytest tests_py/)
    fi
    if [[ "${HAS_C_CPP}" == "true" && "${C_BINDING}" == "headerkit" ]]; then
      echo ">>> [TEST] Verifying C ABI & HeaderKit tripwire..."
      # Tripwire test runs as part of nimble test in tests/test_tripwire.nim
      test -f "${DEST}/tests/test_tripwire.nim"
    fi
    if [[ "${DOCS_ENGINE}" == "starlight" ]]; then
      echo ">>> [TEST] Verifying documentation build for ${FIXTURE} (starlight)..."
      (cd "${DEST}" && just docs-build)
      test -d "${DEST}/docs/dist"
      test -f "${DEST}/docs/dist/index.html"
      echo ">>> [TEST] Documentation build passed and generated docs/dist."
    fi

    # Canonical command surface check: 'just test' must pass cleanly
    echo ">>> [TEST] Verifying canonical command surface 'just test'..."
    (cd "${DEST}" && just test)

    echo ">>> [TEST] ${FIXTURE} test suites passed 100% green."
  fi

  echo ">>> [SUCCESS] Fixture ${FIXTURE} passed all matrix gates!"
done

echo ""
echo "======================================================================"
echo "=== [POLYFORM HARNESS] ALL COMPOSABLE FIXTURES PASSED VERIFICATION ==="
echo "======================================================================"
