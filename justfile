default:
    @just --list

test:
    nimble test

lint:
    nph --check .
    nimble check

fmt:
    nph .

docs:
    pip install --quiet mkdocs-material mkdocstrings-nim
    mkdocs serve

build:
    nimble build -d:release

# Run fixture test suite across flavors (flavor: "all" | "pure_nim" | "nim_ts_wasm" | "nim_python_wheel" | "headerkit_binding")
test-fixtures flavor="all":
    bash tests/test_fixtures.sh {{flavor}} test

# Run fixture linters across flavors
lint-fixtures flavor="all":
    bash tests/test_fixtures.sh {{flavor}} lint

# Run full matrix fixture verification (render, lint, test) across flavors
fixtures flavor="all":
    bash tests/test_fixtures.sh {{flavor}} all

# Manual fallback for template-cleanup (find/replace project_name -> kebab name).
# Cross-platform: uses python3 for find/replace (GNU vs BSD sed differences are avoided).
rename new_name:
    @echo "Renaming project_name -> {{new_name}}"
    @python3 -c "import sys, pathlib; new_kebab = sys.argv[1]; new_snake = new_kebab.replace('-', '_'); root = pathlib.Path('.'); [f.write_text(f.read_text(encoding='utf-8').replace('project_name', new_snake).replace('project-name', new_kebab), encoding='utf-8') for f in root.rglob('*') if f.is_file() and not any(p.startswith('.') for p in f.parts) and f.suffix in {'.nim', '.nimble', '.nims', '.md', '.yml', '.yaml', '.toml'}]" {{new_name}}
    @python3 -c "import sys, pathlib; new_snake = sys.argv[1].replace('-', '_'); nimble = pathlib.Path('project_name.nimble'); nimble.rename(pathlib.Path(f'{new_snake}.nimble')) if nimble.is_file() else None" {{new_name}}

clean:
    rm -rf nimcache htmldocs site
    find . -name '*.exe' -delete
