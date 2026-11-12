#!/usr/bin/env python3
"""
scripts/protect_repo.py - GitHub Repository Security & Branch Protection Manager

Configures and audits GitHub Secret Scanning, Push Protection, and Branch Rulesets
declaratively from .github/rulesets/main-protection.json.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


def run_cmd(args: list[str], input_data: str | None = None) -> tuple[int, str, str]:
    """Execute a subprocess command returning exit code, stdout, and stderr."""
    res = subprocess.run(
        args,
        input=input_data,
        check=False,
        text=True,
        capture_output=True,
    )
    return res.returncode, res.stdout.strip(), res.stderr.strip()


def check_prerequisites() -> None:
    """Verify gh CLI is installed and authenticated."""
    if not shutil.which("gh"):
        print("Error: GitHub CLI ('gh') is required but not installed.", file=sys.stderr)
        print("Install gh from https://cli.github.com/ or via your package manager.", file=sys.stderr)
        sys.exit(1)

    code, _, err = run_cmd(["gh", "auth", "status"])
    if code != 0:
        print("Error: GitHub CLI is not authenticated.", file=sys.stderr)
        print("Run 'gh auth login' before executing repository protection.", file=sys.stderr)
        if err:
            print(f"Details: {err}", file=sys.stderr)
        sys.exit(1)


def find_repo_root() -> Path:
    """Locate the top-level directory of the current git repository."""
    code, out, _ = run_cmd(["git", "rev-parse", "--show-toplevel"])
    if code == 0 and out:
        return Path(out)
    return Path(__file__).resolve().parent.parent


def get_default_repo() -> str:
    """Detect repository owner/name via gh CLI."""
    code, out, err = run_cmd(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"])
    if code == 0 and out:
        return out
    print("Error: Could not automatically detect GitHub repository.", file=sys.stderr)
    print("Ensure git remote 'origin' points to GitHub, or specify --repo OWNER/NAME.", file=sys.stderr)
    if err:
        print(f"Details: {err}", file=sys.stderr)
    sys.exit(1)


def get_security_settings(repo: str) -> dict[str, Any] | None:
    """Fetch repository security_and_analysis settings."""
    code, out, _ = run_cmd(["gh", "api", f"repos/{repo}", "--jq", ".security_and_analysis"])
    if code == 0 and out and out != "null":
        try:
            return json.loads(out)
        except json.JSONDecodeError:
            return None
    return None


def enable_secret_scanning(repo: str) -> bool:
    """Enable Secret Scanning and Push Protection on repository."""
    payload = {
        "security_and_analysis": {
            "secret_scanning": {"status": "enabled"},
            "secret_scanning_push_protection": {"status": "enabled"},
        }
    }
    code, _, err = run_cmd(
        ["gh", "api", "-X", "PATCH", f"repos/{repo}", "--input", "-"],
        input_data=json.dumps(payload),
    )
    if code == 0:
        print(f"[OK] Secret Scanning & Push Protection enabled on {repo}.")
        return True
    else:
        # Some private repos without GHAS may reject enabling secret scanning via API
        print(
            f"[WARN] Could not enable Secret Scanning / Push Protection on {repo} via API.",
            file=sys.stderr,
        )
        print(
            "       Note: Private repositories require GitHub Advanced Security (GHAS).",
            file=sys.stderr,
        )
        if err:
            print(f"       API response: {err}", file=sys.stderr)
        return False


def list_rulesets(repo: str) -> list[dict[str, Any]]:
    """List all rulesets configured on repository."""
    code, out, err = run_cmd(["gh", "api", f"repos/{repo}/rulesets"])
    if code == 0 and out:
        try:
            return json.loads(out)
        except json.JSONDecodeError:
            return []
    if err and "404" not in err:
        print(f"[WARN] Could not fetch rulesets for {repo}: {err}", file=sys.stderr)
    return []


def get_ruleset(repo: str, ruleset_id: int) -> dict[str, Any] | None:
    """Fetch complete ruleset definition by ID."""
    code, out, _ = run_cmd(["gh", "api", f"repos/{repo}/rulesets/{ruleset_id}"])
    if code == 0 and out:
        try:
            return json.loads(out)
        except json.JSONDecodeError:
            return None
    return None


def sanitize_ruleset_payload(data: dict[str, Any]) -> dict[str, Any]:
    """Strip server-generated read-only fields for creation/update."""
    read_only_keys = {
        "id",
        "node_id",
        "created_at",
        "updated_at",
        "_links",
        "source",
        "source_type",
        "current_user_can_bypass",
    }
    return {k: v for k, v in data.items() if k not in read_only_keys}


def check_protection(
    repo: str,
    ruleset_spec: dict[str, Any],
    verbose: bool = False,
) -> bool:
    """Verify repository security settings and ruleset conformance in audit mode."""
    all_ok = True
    print(f"=== Auditing Repository Protection for: {repo} ===")

    # 1. Check Secret Scanning
    sec = get_security_settings(repo)
    if sec:
        ss_status = sec.get("secret_scanning", {}).get("status")
        pp_status = sec.get("secret_scanning_push_protection", {}).get("status")
        if ss_status == "enabled" and pp_status == "enabled":
            print("[OK] Secret Scanning & Push Protection are ACTIVE.")
        else:
            print(
                f"[DRIFT] Secret Scanning ({ss_status}) or Push Protection ({pp_status}) is NOT active.",
                file=sys.stderr,
            )
            all_ok = False
    else:
        print("[INFO] Repository security_and_analysis settings not accessible (or private without GHAS).")

    # 2. Check Ruleset
    name = ruleset_spec.get("name", "main-protection")
    rulesets = list_rulesets(repo)
    matched = next((r for r in rulesets if r.get("name") == name), None)

    if not matched:
        print(f"[DRIFT] Ruleset '{name}' is MISSING on {repo}.", file=sys.stderr)
        return False

    ruleset_id = matched["id"]
    current = get_ruleset(repo, ruleset_id)
    if not current:
        print(f"[DRIFT] Ruleset '{name}' (ID: {ruleset_id}) could not be retrieved.", file=sys.stderr)
        return False

    # Verify enforcement
    desired_enforcement = ruleset_spec.get("enforcement", "active")
    if current.get("enforcement") != desired_enforcement:
        print(
            f"[DRIFT] Ruleset '{name}' enforcement is '{current.get('enforcement')}', expected '{desired_enforcement}'.",
            file=sys.stderr,
        )
        all_ok = False
    else:
        if verbose:
            print(f"[OK] Ruleset enforcement is '{desired_enforcement}'.")

    # Verify rule types presence
    current_rule_types = {r.get("type") for r in current.get("rules", [])}
    desired_rule_types = {r.get("type") for r in ruleset_spec.get("rules", [])}
    missing_rules = desired_rule_types - current_rule_types
    if missing_rules:
        print(f"[DRIFT] Ruleset '{name}' is missing rule types: {sorted(missing_rules)}", file=sys.stderr)
        all_ok = False
    else:
        if verbose:
            print(f"[OK] All expected rule types present: {sorted(desired_rule_types)}")

    # Verify required status checks
    desired_checks_rule = next(
        (r for r in ruleset_spec.get("rules", []) if r.get("type") == "required_status_checks"),
        None,
    )
    if desired_checks_rule:
        current_checks_rule = next(
            (r for r in current.get("rules", []) if r.get("type") == "required_status_checks"),
            None,
        )
        if not current_checks_rule:
            print(f"[DRIFT] Ruleset '{name}' is missing 'required_status_checks' rule.", file=sys.stderr)
            all_ok = False
        else:
            desired_contexts = {
                c.get("context")
                for c in desired_checks_rule.get("parameters", {}).get("required_status_checks", [])
            }
            current_contexts = {
                c.get("context")
                for c in current_checks_rule.get("parameters", {}).get("required_status_checks", [])
            }
            missing_contexts = desired_contexts - current_contexts
            if missing_contexts:
                print(
                    f"[DRIFT] Ruleset '{name}' missing required status check contexts: {sorted(missing_contexts)}",
                    file=sys.stderr,
                )
                all_ok = False
            else:
                if verbose:
                    print(f"[OK] Required status checks match: {sorted(desired_contexts)}")

    if all_ok:
        print(f"[OK] Repository protection ruleset '{name}' (ID: {ruleset_id}) is fully compliant.")
    return all_ok


def apply_protection(
    repo: str,
    ruleset_spec: dict[str, Any],
) -> bool:
    """Apply repository security settings and sync ruleset declaratively."""
    print(f"=== Applying Repository Protection for: {repo} ===")

    # 1. Enable Secret Scanning & Push Protection
    sec = get_security_settings(repo)
    if not sec or sec.get("secret_scanning", {}).get("status") != "enabled" or \
       sec.get("secret_scanning_push_protection", {}).get("status") != "enabled":
        enable_secret_scanning(repo)
    else:
        print(f"[OK] Secret Scanning & Push Protection are already enabled on {repo}.")

    # 2. Sync Branch Protection Ruleset
    name = ruleset_spec.get("name", "main-protection")
    payload = sanitize_ruleset_payload(ruleset_spec)
    rulesets = list_rulesets(repo)
    matched = next((r for r in rulesets if r.get("name") == name), None)

    if matched:
        ruleset_id = matched["id"]
        code, out, err = run_cmd(
            ["gh", "api", "-X", "PUT", f"repos/{repo}/rulesets/{ruleset_id}", "--input", "-"],
            input_data=json.dumps(payload),
        )
        if code == 0:
            print(f"[SUCCESS] Updated existing ruleset '{name}' (ID: {ruleset_id}) on {repo}.")
            return True
        else:
            print(f"Error: Failed to update ruleset '{name}': {err}", file=sys.stderr)
            return False
    else:
        code, out, err = run_cmd(
            ["gh", "api", "-X", "POST", f"repos/{repo}/rulesets", "--input", "-"],
            input_data=json.dumps(payload),
        )
        if code == 0:
            res = json.loads(out)
            new_id = res.get("id")
            print(f"[SUCCESS] Created ruleset '{name}' (ID: {new_id}) on {repo}.")
            return True
        else:
            print(f"Error: Failed to create ruleset '{name}': {err}", file=sys.stderr)
            return False


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Declaratively configure and verify GitHub secret scanning & branch rulesets.",
    )
    parser.add_argument(
        "--repo",
        help="GitHub repository in OWNER/NAME format (default: auto-detected)",
        default=None,
    )
    parser.add_argument(
        "--ruleset",
        help="Path to ruleset JSON definition file (default: .github/rulesets/main-protection.json)",
        default=None,
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Audit mode: verify settings match declaration without modifying (exits non-zero on drift)",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable detailed inspection output",
    )

    args = parser.parse_args()
    check_prerequisites()

    repo = args.repo or get_default_repo()
    root = find_repo_root()

    ruleset_path = Path(args.ruleset) if args.ruleset else (root / ".github" / "rulesets" / "main-protection.json")
    if not ruleset_path.exists():
        print(f"Error: Ruleset definition file not found at {ruleset_path}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(ruleset_path, "r", encoding="utf-8") as f:
            ruleset_spec = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"Error reading ruleset JSON at {ruleset_path}: {e}", file=sys.stderr)
        sys.exit(1)

    if args.check:
        ok = check_protection(repo, ruleset_spec, verbose=args.verbose)
        sys.exit(0 if ok else 1)
    else:
        ok = apply_protection(repo, ruleset_spec)
        sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
