Repo Cleanup - Quick Usage

From repository root:

Dry-run only (recommended first):

```bash
python .agent/skills/repo-cleanup/scripts/cleanup_repo.py
```

Remove found items (interactive confirmation):

```bash
python .agent/skills/repo-cleanup/scripts/cleanup_repo.py --remove
```

Remove without prompt (use carefully):

```bash
python .agent/skills/repo-cleanup/scripts/cleanup_repo.py --remove --yes
```

Exclude a folder from matching (substring match):

```bash
python .agent/skills/repo-cleanup/scripts/cleanup_repo.py --exclude "frontend/node_modules,.git"
```

Customize patterns:

```bash
python .agent/skills/repo-cleanup/scripts/cleanup_repo.py --patterns "__pycache__,*.pyc,*.log"
```
