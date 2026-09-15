#!/usr/bin/env python3
"""Safe repository cleanup utility.

Scans the repository and reports matches for common unwanted files/directories.
By default it runs a dry-run. To remove matches, pass `--remove` and to skip
confirmation pass `--yes`.
"""
from __future__ import annotations

import argparse
import fnmatch
import os
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Tuple


DEFAULT_PATTERNS = [
    "__pycache__",
    "*.pyc",
    ".DS_Store",
    ".pytest_cache",
    "build",
    "dist",
    "*.egg-info",
    "venv",
    ".venv",
    "env",
    "node_modules",
]


@dataclass
class Match:
    path: Path
    is_dir: bool


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Safe repository cleanup tool")
    p.add_argument("--patterns", type=str, default=",".join(DEFAULT_PATTERNS),
                   help="Comma-separated glob patterns to match (default common patterns)")
    p.add_argument("--exclude", type=str, default="",
                   help="Comma-separated list of paths to exclude (substring match)")
    p.add_argument("--root", type=str, default=".", help="Root path to scan")
    p.add_argument("--remove", action="store_true", help="Actually remove matched files/dirs")
    p.add_argument("--yes", action="store_true", help="Skip confirmation when --remove is used")
    p.add_argument("--max-depth", type=int, default=10, help="Maximum recursion depth")
    p.add_argument("--follow-symlinks", action="store_true", help="Follow symlinks when scanning")
    return p.parse_args()


def compile_patterns(patterns_csv: str) -> List[str]:
    return [p.strip() for p in patterns_csv.split(",") if p.strip()]


def compile_excludes(exclude_csv: str) -> List[str]:
    return [e.strip() for e in exclude_csv.split(",") if e.strip()]


def is_excluded(path: Path, excludes: List[str]) -> bool:
    s = str(path)
    for ex in excludes:
        if ex and ex in s:
            return True
    return False


def find_matches(root: Path, patterns: List[str], excludes: List[str], max_depth: int, follow_symlinks: bool) -> List[Match]:
    matches: List[Match] = []

    root = root.resolve()

    def walk(current: Path, depth: int) -> None:
        if depth < 0:
            return
        try:
            for entry in current.iterdir():
                try:
                    if is_excluded(entry, excludes):
                        continue
                    name = entry.name
                    # Check direct name patterns first (fast)
                    matched = False
                    for pat in patterns:
                        if pat == name or fnmatch.fnmatch(name, pat):
                            matches.append(Match(path=entry, is_dir=entry.is_dir()))
                            matched = True
                            break
                    if matched:
                        # don't descend into matched directories to avoid double reporting
                        continue
                    if entry.is_dir() and (follow_symlinks or not entry.is_symlink()):
                        walk(entry, depth - 1)
                except PermissionError:
                    print(f"PermissionError accessing {entry}", file=sys.stderr)
                except OSError as e:
                    print(f"OS error accessing {entry}: {e}", file=sys.stderr)
        except PermissionError:
            print(f"PermissionError accessing {current}", file=sys.stderr)

    walk(root, max_depth)
    # Deduplicate by resolved path
    unique = {}
    for m in matches:
        key = str(m.path.resolve())
        if key not in unique:
            unique[key] = m
    return list(unique.values())


def remove_matches(matches: List[Match], yes: bool) -> Tuple[int, int]:
    removed_files = 0
    removed_dirs = 0
    if not matches:
        return removed_files, removed_dirs

    if not yes:
        print("About to remove the following items:")
        for m in matches:
            print(f" - {m.path} ")
        ans = input("Proceed and delete these items? [y/N]: ").strip().lower()
        if ans not in ("y", "yes"):
            print("Aborting deletion.")
            return 0, 0

    for m in matches:
        try:
            if m.is_dir:
                shutil.rmtree(m.path)
                removed_dirs += 1
            else:
                m.path.unlink()
                removed_files += 1
        except Exception as e:
            print(f"Failed to remove {m.path}: {e}", file=sys.stderr)

    return removed_files, removed_dirs


def format_report(matches: List[Match]) -> str:
    lines = []
    if not matches:
        return "No matches found."
    lines.append(f"Found {len(matches)} item(s):")
    for m in matches:
        t = "dir" if m.is_dir else "file"
        lines.append(f" - [{t}] {m.path}")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    patterns = compile_patterns(args.patterns)
    excludes = compile_excludes(args.exclude)
    root = Path(args.root)

    print(f"Scanning {root.resolve()} for patterns: {patterns}")
    if excludes:
        print(f"Excluding paths containing: {excludes}")

    matches = find_matches(root, patterns, excludes, args.max_depth, args.follow_symlinks)
    print(format_report(matches))

    if args.remove:
        files_removed, dirs_removed = remove_matches(matches, args.yes)
        print(f"Removed {files_removed} files and {dirs_removed} directories.")
    else:
        print("Dry-run only. Use --remove to delete matches.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
