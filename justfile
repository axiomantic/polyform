default:
    @just --list

# 1. Verification & Test Suite
test flavor="all":
    bash tests/test_fixtures.sh {{flavor}} test

# 2. Matrix Fixture Verification (Render, Lint, Test)
fixtures flavor="all":
    bash tests/test_fixtures.sh {{flavor}} all

# 3. Linter Execution
lint flavor="all":
    bash tests/test_fixtures.sh {{flavor}} lint

# 4. Formatter Execution
fmt:
    uvx copier --version >/dev/null 2>&1 || true

# 5. Clean Temporary Fixtures & Artifacts
clean:
    rm -rf /tmp/polyform-fixtures-* nimcache site
