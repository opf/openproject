# Repo Cleanup Skill

Purpose: a safe, configurable skill to locate and optionally remove common repository clutter (pyc files, __pycache__, .DS_Store, .pytest_cache, virtualenvs) with dry-run and explicit confirmation.

Behavior:
- Scans the workspace recursively for configurable patterns.
- Shows a dry-run report by default.
- Requires `--remove` and `--yes` to actually delete items.
- Provides an allowlist and denylist for patterns and paths.

Usage (from repo root):

```bash
# Dry-run (default)
python .agent/skills/repo-cleanup/scripts/cleanup_repo.py

# Remove found items (prompts for confirmation)
python .agent/skills/repo-cleanup/scripts/cleanup_repo.py --remove

# Remove without interactive prompt
python .agent/skills/repo-cleanup/scripts/cleanup_repo.py --remove --yes

# Customize patterns
python .agent/skills/repo-cleanup/scripts/cleanup_repo.py --patterns "__pycache__,*.pyc,.DS_Store" --exclude "frontend/node_modules"
```

Safety notes:
- The script defaults to dry-run; nothing is deleted unless `--remove` is used.
- For destructive operations you must pass `--yes` to skip the final confirmation.
- Use `--exclude` for paths you absolutely want preserved.

Where to integrate:
- This skill is intended for interactive developer sessions, pre-commit maintenance, or CI housekeeping (with caution).
