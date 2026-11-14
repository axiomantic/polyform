#!/usr/bin/env python3
"""Polyform Onboarding & Template Upgrade Protocol Helper."""

import argparse
import datetime
import os
import re
import subprocess
import sys

BANNER_START = "<!-- POLYFORM_ONBOARDING_START -->"
BANNER_END = "<!-- POLYFORM_ONBOARDING_END -->"

BANNER_TEXT = """<!-- POLYFORM_ONBOARDING_START -->
> [!IMPORTANT]
> **Pending Polyform Configuration / Upgrade:**
> Read `ONBOARDING.md` and guide the operator through configuring or updating this project.
> Once all steps are completed and approved by the operator, run `just finish-onboarding` to delete `ONBOARDING.md`, strip this banner, and commit the provenance trailer.
<!-- POLYFORM_ONBOARDING_END -->"""


def strip_banner(agents_file: str) -> bool:
    """Strip the onboarding banner from AGENTS.md."""
    if not os.path.isfile(agents_file):
        return False
    with open(agents_file, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = re.compile(
        r"<!-- POLYFORM_ONBOARDING_START -->.*?<!-- POLYFORM_ONBOARDING_END -->\n*",
        re.DOTALL,
    )
    if not pattern.search(content):
        return False

    new_content = pattern.sub("", content).lstrip()
    with open(agents_file, "w", encoding="utf-8") as f:
        f.write(new_content)
    return True


def inject_banner(agents_file: str) -> bool:
    """Prepend the onboarding banner to AGENTS.md if not present."""
    if not os.path.isfile(agents_file):
        return False
    with open(agents_file, "r", encoding="utf-8") as f:
        content = f.read()

    if BANNER_START in content:
        return False

    new_content = BANNER_TEXT + "\n\n" + content
    with open(agents_file, "w", encoding="utf-8") as f:
        f.write(new_content)
    return True


def get_template_ref(repo_root: str) -> str:
    """Extract current _commit ref from .copier-answers.yml."""
    answers_file = os.path.join(repo_root, ".copier-answers.yml")
    if os.path.isfile(answers_file):
        with open(answers_file, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("_commit:"):
                    return line.split(":", 1)[1].strip().strip('"').strip("'")
    return "HEAD"


def finish_onboarding(repo_root: str) -> None:
    """Remove ONBOARDING.md, strip banner from AGENTS.md, and commit with trailers."""
    onboarding_file = os.path.join(repo_root, "ONBOARDING.md")
    agents_file = os.path.join(repo_root, "AGENTS.md")

    removed_file = False
    if os.path.isfile(onboarding_file):
        os.remove(onboarding_file)
        removed_file = True

    stripped_banner = strip_banner(agents_file)

    if not removed_file and not stripped_banner:
        print("Notice: No pending onboarding artifacts found. Workspace is already clean.")
        return

    # Check if repository has an existing commit
    has_commits = (
        subprocess.run(
            ["git", "rev-parse", "--verify", "HEAD"],
            cwd=repo_root,
            capture_output=True,
        ).returncode
        == 0
    )

    # Git stage modified/removed files
    if not has_commits:
        subprocess.run(["git", "add", "-A"], cwd=repo_root, check=True)
    else:
        subprocess.run(["git", "add", "-u"], cwd=repo_root, check=True)
        diff_check = subprocess.run(
            ["git", "diff", "--cached", "--quiet"],
            cwd=repo_root,
        )
        if diff_check.returncode == 0:
            print("Notice: No staged changes to commit after cleanup.")
            return

    ref = get_template_ref(repo_root)
    timestamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    action = "scaffold project and complete onboarding" if not has_commits else "complete onboarding"
    commit_msg = (
        f"chore(polyform): {action}\n\n"
        f"Polyform-Template-Ref: {ref}\n"
        f"Polyform-Onboarded-At: {timestamp}\n"
    )

    subprocess.run(
        [
            "git",
            "commit",
            "-m",
            commit_msg,
        ],
        cwd=repo_root,
        check=True,
    )
    print(f"Successfully finished onboarding. Provenance trailer stamped: Polyform-Template-Ref: {ref}")


def rearm_onboarding(repo_root: str, prev_ref: str, next_ref: str) -> None:
    """Re-arm onboarding banner in AGENTS.md and regenerate ONBOARDING.md."""
    agents_file = os.path.join(repo_root, "AGENTS.md")
    inject_banner(agents_file)

    onboarding_file = os.path.join(repo_root, "ONBOARDING.md")
    if not os.path.isfile(onboarding_file):
        with open(onboarding_file, "w", encoding="utf-8") as f:
            f.write(
                f"# Polyform Template Upgrade Protocol ({prev_ref} -> {next_ref})\n\n"
                f"> [!IMPORTANT]\n"
                f"> Polyform has been upgraded from `{prev_ref}` to `{next_ref}`.\n"
                f"> Review `git diff HEAD~1` to inspect incoming template modifications.\n"
                f"> Guide the operator through newly introduced features and decisions.\n"
                f"> Once complete and verified, run `just finish-onboarding` to clean up and commit.\n"
            )
    print(f"Re-armed onboarding protocol for template upgrade ({prev_ref} -> {next_ref}).")


def main() -> None:
    parser = argparse.ArgumentParser(description="Polyform Onboarding Protocol Helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("finish", help="Complete onboarding and commit with trailers")

    rearm_parser = subparsers.add_parser("rearm", help="Re-arm onboarding after template update")
    rearm_parser.add_argument("--from", dest="from_ref", default="unknown", help="Previous template ref")
    rearm_parser.add_argument("--to", dest="to_ref", default="HEAD", help="New template ref")

    args = parser.parse_args()
    repo_root = os.getcwd()

    if args.command == "finish":
        finish_onboarding(repo_root)
    elif args.command == "rearm":
        rearm_onboarding(repo_root, args.from_ref, args.to_ref)


if __name__ == "__main__":
    main()
