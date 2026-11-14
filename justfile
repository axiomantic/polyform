import? 'justfile.local'

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

# 5. Documentation Dev Server & Production Build
docs:
    cd docs && npm install && npm run dev

docs-build:
    cd docs && npm install && npm run build

# 6. Clean Temporary Fixtures & Artifacts
clean:
    rm -rf /tmp/polyform-fixtures-* nimcache site docs/dist docs/.astro docs/node_modules

# Clean local build and test nimcaches
clean-cache:
    rm -rf nimcache /tmp/polyform-fixtures-*

# 7. Secret Scanning
check-secrets:
    @if command -v gitleaks >/dev/null 2>&1; then \
        gitleaks detect -v; \
    elif command -v pre-commit >/dev/null 2>&1; then \
        pre-commit run gitleaks --all-files; \
    else \
        echo "Error: neither gitleaks nor pre-commit found. Install gitleaks or pre-commit." >&2; exit 1; \
    fi

# 8. Repository Security & Branch Protection
protect-repo:
    python3 scripts/protect_repo.py

check-protection:
    python3 scripts/protect_repo.py --check

# 9. Upstream Template Synchronization & Onboarding
finish-onboarding *FLAGS:
    python3 scripts/onboard.py finish {{ FLAGS }}
