#!/usr/bin/env python3
"""Polyform Onboarding & Template Upgrade Protocol Helper.

Manages the self-destructing onboarding protocol for AI coding assistants:
- finish: Cleans up ONBOARDING.md, strips the banner from AGENTS.md, stages files,
          and commits with RFC 822 Polyform-Template-Ref and Polyform-Onboarded-At trailers.
- rearm:  Re-arms the protocol after a Copier template update by injecting the banner
          into AGENTS.md and generating a rich, actionable ONBOARDING.md upgrade playbook.
"""

from __future__ import annotations

import argparse
import datetime
import os
import re
import subprocess

BANNER_START = "<!-- POLYFORM_ONBOARDING_START -->"
BANNER_END = "<!-- POLYFORM_ONBOARDING_END -->"

BANNER_TEXT = """<!-- POLYFORM_ONBOARDING_START -->
> [!IMPORTANT]
> **Pending Polyform Configuration / Upgrade:**
> Read `ONBOARDING.md` and guide the operator through configuring or updating this project.
> Once all steps are completed and approved by the operator, run `just finish-onboarding` to delete `ONBOARDING.md`, strip this banner, and commit the provenance trailer.
<!-- POLYFORM_ONBOARDING_END -->"""

# Curated catalog of upstream capabilities introduced across Polyform releases
VERSION_HIGHLIGHTS: dict[str, list[str]] = {
    "v0.5.0": [
        "**Secret Scanning**: Gitleaks integrated into GitHub Actions CI and local `just check-secrets`.",
        "**Branch Protection**: Automated GitHub ruleset enforcement via `just protect-repo` and `just check-protection`.",
    ],
    "v0.6.0": [
        "**Test Runner Hardening**: Nimble per-suite `runSuite` timeout wrapper in `*.nimble` preventing hung tests from hanging CI.",
        "**Multi-Flavor Fixture Validation**: Automated cross-platform matrix testing across 8 distinct configurations.",
    ],
    "v0.7.0": [
        "**Apple Silicon GPU Runner (`gh-krun-runner`) [Experimental / WIP]**: Ephemeral self-hosted Linux ARM64 microVM runner for Apple Silicon hosts via `krunkit` + Virtio-GPU Venus (`/dev/dri/renderD128`, Vulkan 1.3), saving 10x-billed macOS cloud runner minutes.",
        "**Active AI Onboarding Protocol**: Self-destructing `ONBOARDING.md`, line 1 banner in `AGENTS.md`, and clean RFC 822 `Polyform-Template-Ref:` git commit trailers.",
        "**Template Synchronization Automation**: Enhanced `just update-template` with automatic delta re-arming and migration playbooks.",
    ],
}


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


def get_last_onboarded_ref(repo_root: str) -> str | None:
    """Extract last recorded Polyform-Template-Ref git commit trailer."""
    res = subprocess.run(
        [
            "git",
            "log",
            "-1",
            "--grep=Polyform-Template-Ref:",
            "--format=%(trailers:key=Polyform-Template-Ref,valueonly)",
        ],
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    trailer = res.stdout.strip()
    return trailer if trailer else None


def inspect_git_delta(repo_root: str) -> tuple[list[str], list[str], list[str], list[str], str]:
    """Inspect working tree after copier update.

    Returns:
        (conflicts, modified, added, deleted, diff_stat)
    """
    conflicts: list[str] = []
    modified: list[str] = []
    added: list[str] = []
    deleted: list[str] = []

    res = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    for line in res.stdout.splitlines():
        if not line:
            continue
        code = line[:2]
        path = line[3:].strip()
        if "U" in code or code in ("AA", "DD"):
            conflicts.append(path)
        elif "M" in code:
            modified.append(path)
        elif "A" in code or "??" in code:
            added.append(path)
        elif "D" in code:
            deleted.append(path)

    # Check for conflict markers in tracked files if none caught by status
    if not conflicts:
        grep_res = subprocess.run(
            ["git", "grep", "-l", "^<<<<<<< "],
            cwd=repo_root,
            capture_output=True,
            text=True,
            check=False,
        )
        if grep_res.returncode == 0:
            for match in grep_res.stdout.splitlines():
                if match and match not in conflicts:
                    conflicts.append(match)

    stat_res = subprocess.run(
        ["git", "diff", "--stat"],
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    diff_stat = stat_res.stdout.strip()

    return conflicts, modified, added, deleted, diff_stat


def get_version_highlights_span(from_ref: str, to_ref: str) -> list[tuple[str, list[str]]]:
    """Return applicable version highlights between from_ref and to_ref."""
    # Normalized versions sorted ascending
    known_versions = ["v0.5.0", "v0.6.0", "v0.7.0"]
    applicable = []

    for ver in known_versions:
        # If from_ref is unknown or preceding, and to_ref is >= this version
        # We include it if it's new compared to from_ref
        if from_ref != ver and ver in VERSION_HIGHLIGHTS:
            applicable.append((ver, VERSION_HIGHLIGHTS[ver]))

    return applicable if applicable else list(VERSION_HIGHLIGHTS.items())


def finish_onboarding(repo_root: str, no_commit: bool = False) -> None:
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
            check=False,
        ).returncode
        == 0
    )

    # Git stage all modified, added, and removed files so domain hydration isn't orphaned
    subprocess.run(["git", "add", "-A"], cwd=repo_root, check=True)

    if no_commit:
        print("Notice: Cleaned onboarding files and staged changes (--no-commit specified).")
        return

    diff_check = subprocess.run(
        ["git", "diff", "--cached", "--quiet"],
        cwd=repo_root,
        check=False,
    )
    if diff_check.returncode == 0:
        print("Notice: No staged changes to commit after cleanup.")
        return

    ref = get_template_ref(repo_root)
    prev_ref = get_last_onboarded_ref(repo_root)
    timestamp = datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%dT%H:%M:%SZ")

    if not has_commits:
        action = "scaffold project and complete onboarding"
    elif prev_ref and prev_ref != ref:
        action = f"upgrade template from {prev_ref} to {ref} and complete onboarding"
    else:
        action = "complete onboarding"

    commit_msg = (
        f"chore(polyform): {action}\n\n"
        f"Polyform-Template-Ref: {ref}\n"
        f"Polyform-Onboarded-At: {timestamp}\n"
    )

    subprocess.run(
        ["git", "commit", "-m", commit_msg],
        cwd=repo_root,
        check=True,
    )
    print(f"Successfully finished onboarding. Provenance trailer stamped:\n  Polyform-Template-Ref: {ref}\n  Polyform-Onboarded-At: {timestamp}")


def rearm_onboarding(repo_root: str, prev_ref: str, next_ref: str) -> None:
    """Re-arm onboarding banner in AGENTS.md and generate a rich ONBOARDING.md."""
    agents_file = os.path.join(repo_root, "AGENTS.md")
    inject_banner(agents_file)

    # Inspect current repository delta following Copier update
    conflicts, modified, added, deleted, diff_stat = inspect_git_delta(repo_root)
    highlights = get_version_highlights_span(prev_ref, next_ref)

    lines = [
        f"# Polyform Template Upgrade Protocol ({prev_ref} -> {next_ref})",
        "",
        "> [!IMPORTANT]",
        f"> **Polyform Template Upgrade Migration:** Upgraded upstream from `{prev_ref}` to `{next_ref}`.",
        "> For AI Coding Assistants (Claude Code, Antigravity, OpenCode, Codex, Cursor):",
        "> Execute this checklist to audit template updates, resolve merge conflicts, and verify repository invariants.",
        "> Once complete and verified with the operator, run `just finish-onboarding` to delete this file, strip the `AGENTS.md` banner, and commit the updated provenance trailer.",
        "",
        "---",
        "",
        "## 1. Copier Working Tree Delta & Status",
        "",
    ]

    if conflicts:
        lines.extend([
            "> [!CAUTION]",
            f"> **{len(conflicts)} Merge Conflict(s) Detected:** Copier update produced merge conflicts.",
            "> Inspect and resolve the conflict markers (`<<<<<<<` ... `>>>>>>>`) before running test suites.",
            "",
            "**Conflicted Files:**",
        ])
        for c in conflicts:
            lines.append(f"- [ ] `{c}` (Resolve conflict markers)")
        lines.append("")
    else:
        lines.append("No 3-way merge conflicts detected in working tree.")
        lines.append("")

    if modified:
        lines.append(f"**Modified Template Files ({len(modified)}):**")
        for m in modified:
            lines.append(f"- `{m}`")
        lines.append("")

    if added:
        lines.append(f"**Newly Introduced Files ({len(added)}):**")
        for a in added:
            lines.append(f"- `{a}`")
        lines.append("")

    if deleted:
        lines.append(f"**Deleted Files ({len(deleted)}):**")
        for d in deleted:
            lines.append(f"- `{d}`")
        lines.append("")

    if diff_stat:
        lines.extend([
            "<details>",
            "<summary><strong>View Detailed Diff Stat</strong></summary>",
            "",
            "```text",
            diff_stat,
            "```",
            "",
            "</details>",
            "",
        ])

    lines.extend([
        "---",
        "",
        "## 2. Upstream Version Migration Highlights",
        "",
    ])

    for ver, points in highlights:
        lines.append(f"### Polyform `{ver}`")
        for pt in points:
            lines.append(f"- {pt}")
        lines.append("")

    lines.extend([
        "---",
        "",
        "## 3. Step-by-Step Upgrade Checklist",
        "",
        "1. **Resolve Merge Conflicts (if any)**:",
        "   Inspect files listed in Section 1. Ensure `justfile` and `.copier-answers.yml` syntax remains valid.",
        "",
        "2. **Verify Baseline Command Surface**:",
        "   Run the canonical validation suite:",
        "   ```bash",
        "   just setup && just test && just lint && just check-secrets",
        "   ```",
        "",
        "3. **Inspect Newly Introduced Capabilities**:",
        "   - If `v0.7.0`: Review if `ci_gpu_runner: krun_apple_silicon` is desired (see Section 5 in `NEXT_STEPS.md`).",
        "   - If `v0.6.0`: Check custom test tasks in `*.nimble` to ensure they use `runSuite` timeout wrapper.",
        "   - If `v0.5.0`: Verify repository security rulesets via `just check-protection`.",
        "",
        "4. **Consult Operator**:",
        "   Present a concise summary of changes to the operator. Only ask questions about *new* features or conflict decisions.",
        "",
        "---",
        "",
        "## 4. Finalization & Provenance Stamping",
        "",
        "Once verified green and ratified by the operator:",
        "```bash",
        "just finish-onboarding",
        "```",
        "*(Or run `just finish-onboarding --no-commit` if you wish to review git diff and commit manually).* \n",
    ])

    onboarding_file = os.path.join(repo_root, "ONBOARDING.md")
    with open(onboarding_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"Re-armed onboarding protocol for template upgrade ({prev_ref} -> {next_ref}).")
    print(f"Generated comprehensive upgrade playbook in {onboarding_file}.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Polyform Onboarding Protocol Helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    finish_parser = subparsers.add_parser("finish", help="Complete onboarding and commit with trailers")
    finish_parser.add_argument(
        "--no-commit",
        action="store_true",
        help="Strip banner and delete ONBOARDING.md, but stage changes without committing",
    )

    rearm_parser = subparsers.add_parser("rearm", help="Re-arm onboarding after template update")
    rearm_parser.add_argument("--from", dest="from_ref", default="unknown", help="Previous template ref")
    rearm_parser.add_argument("--to", dest="to_ref", default="HEAD", help="New template ref")

    args = parser.parse_args()
    repo_root = os.getcwd()

    if args.command == "finish":
        finish_onboarding(repo_root, no_commit=args.no_commit)
    elif args.command == "rearm":
        rearm_onboarding(repo_root, args.from_ref, args.to_ref)


if __name__ == "__main__":
    main()
