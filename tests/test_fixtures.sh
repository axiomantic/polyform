#!/usr/bin/env bash
# tests/test_fixtures.sh - Polyform Root Matrix Fixture Test Runner
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export PATH="${HOME}/.nimble/bin:${PATH}"

TARGET_FLAVOR="${1:-all}"
MODE="${2:-all}" # all | test | lint

if [[ "${TARGET_FLAVOR}" == "all" ]]; then
  FLAVORS=("pure_nim" "nim_ts_wasm" "nim_python_wheel" "headerkit_binding")
else
  FLAVORS=("${TARGET_FLAVOR}")
fi

FIXTURE_DIR="$(mktemp -d /tmp/polyform-fixtures-XXXXXX)"
trap 'rm -rf "${FIXTURE_DIR}"' EXIT

echo "=== [POLYFORM ROOT HARNESS] Starting Fixture Matrix Verification ==="
echo "Target Flavors : ${FLAVORS[*]}"
echo "Mode           : ${MODE}"
echo "Repository Root: ${REPO_ROOT}"
echo "Staging Root   : ${FIXTURE_DIR}"

for FLAVOR in "${FLAVORS[@]}"; do
  echo ""
  echo "======================================================================"
  echo ">>> [FLAVOR] Rendering & Verifying: ${FLAVOR}"
  echo "======================================================================"
  
  DEST="${FIXTURE_DIR}/${FLAVOR}"
  
  case "${FLAVOR}" in
    pure_nim)
      PKG_SLUG="fixture_pure"
      REPO_SLUG="fixture-pure"
      DOCS_ENGINE="starlight"
      ;;
    nim_ts_wasm)
      PKG_SLUG="fixture_wasm"
      REPO_SLUG="fixture-wasm"
      DOCS_ENGINE="none"
      ;;
    nim_python_wheel)
      PKG_SLUG="fixture_wheel"
      REPO_SLUG="fixture-wheel"
      DOCS_ENGINE="none"
      ;;
    headerkit_binding)
      PKG_SLUG="fixture_hk"
      REPO_SLUG="fixture-hk"
      DOCS_ENGINE="none"
      ;;
    *)
      PKG_SLUG="fixture_${FLAVOR}"
      REPO_SLUG="fixture-${FLAVOR//_/-}"
      DOCS_ENGINE="none"
      ;;
  esac
  
  uvx copier copy --vcs-ref=HEAD --trust --defaults \
    -d project_name="Fixture ${FLAVOR}" \
    -d repo_name="${REPO_SLUG}" \
    -d package_name="${PKG_SLUG}" \
    -d flavor="${FLAVOR}" \
    -d docs_engine="${DOCS_ENGINE}" \
    "${REPO_ROOT}" "${DEST}"

  echo ">>> [VERIFY] Checking .copier-answers.yml, workflows, and justfile extension hooks..."
  test -f "${DEST}/.copier-answers.yml"
  test -f "${DEST}/.github/workflows/ci.yml"
  grep -q "import? 'justfile.local'" "${DEST}/justfile"
  echo "test-hook:" > "${DEST}/justfile.local"
  echo "    @echo 'local-hook-active'" >> "${DEST}/justfile.local"
  LOCAL_HOOK_OUT=$(cd "${DEST}" && just test-hook)
  rm -f "${DEST}/justfile.local"
  if [[ "${LOCAL_HOOK_OUT}" != "local-hook-active" ]]; then
    echo "ERROR: justfile.local extension hook failed to execute in ${FLAVOR}" >&2
    exit 1
  fi

  echo ">>> [SETUP] Installing required toolchain dependencies for ${FLAVOR}..."
  if [[ "${FLAVOR}" == "nim_ts_wasm" ]]; then
    (cd "${DEST}" && npm install --no-audit --no-fund)
  fi
  if [[ "${DOCS_ENGINE}" == "starlight" ]]; then
    (cd "${DEST}/docs" && npm install --no-audit --no-fund)
  fi

  # LINT VERIFICATION
  if [[ "${MODE}" == "all" || "${MODE}" == "lint" ]]; then
    echo ">>> [LINT] Running linters for ${FLAVOR}..."
    (cd "${DEST}" && nph --check .)
    (cd "${DEST}" && nimble check)
    if [[ "${FLAVOR}" == "nim_ts_wasm" ]]; then
      (cd "${DEST}" && npx tsc --noEmit)
    elif [[ "${FLAVOR}" == "nim_python_wheel" ]]; then
      (cd "${DEST}" && uv run --with ruff ruff check .)
    fi
    echo ">>> [LINT] ${FLAVOR} linters passed cleanly."
  fi

  # TEST VERIFICATION
  if [[ "${MODE}" == "all" || "${MODE}" == "test" ]]; then
    echo ">>> [TEST] Running test suites for ${FLAVOR}..."
    (cd "${DEST}" && nimble test)
    if [[ "${FLAVOR}" == "nim_ts_wasm" ]]; then
      echo ">>> [BUILD] Compiling WASM module..."
      (cd "${DEST}" && bash scripts/compile_wasm.sh)
      test -f "${DEST}/dist/${PKG_SLUG}.wasm"
      (cd "${DEST}" && npx vitest run)
    elif [[ "${FLAVOR}" == "nim_python_wheel" ]]; then
      (cd "${DEST}" && uv run --with pytest pytest tests_py/)
    fi
    if [[ "${DOCS_ENGINE}" == "starlight" ]]; then
      echo ">>> [TEST] Verifying documentation build for ${FLAVOR} (starlight)..."
      (cd "${DEST}" && just docs-build)
      test -d "${DEST}/docs/dist"
      test -f "${DEST}/docs/dist/index.html"
      echo ">>> [TEST] Documentation build passed and generated docs/dist."
    fi
    echo ">>> [TEST] ${FLAVOR} test suites passed 100% green."
  fi

  echo ">>> [SUCCESS] Flavor ${FLAVOR} passed all matrix gates!"
done

echo ""
echo "======================================================================"
echo "=== [POLYFORM HARNESS] ALL FLAVORS PASSED THREE-KEY VERIFICATION   ==="
echo "======================================================================"
