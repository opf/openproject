---
name: git-commit
description: Creates properly formatted Git commits using Conventional Commit style with awareness of ESG Sustainify's Vertical Slice Architecture. Analyzes project structure to suggest appropriate commit type and scope. Use when the user asks to commit changes, save work to Git, or create a commit message.
---

# Git Commit Skill

This skill enables the agent to create well-formatted Git commits following Conventional Commit standards, with intelligent analysis of the ESG Sustainify project structure.

## When to use this skill

- User asks to "commit changes" or "save work"
- User asks to "make a commit" or "create a commit message"
- User requests to "push changes" (after committing)
- Completing a feature, bug fix, or documentation task
- Language like "git commit" or "commit this code"

## How to use this skill

### Step 1: Analyze staged changes

Execute the analysis script to categorize changes and receive commit suggestions:

```bash
python .agent/skills/git-commit/scripts/analyze_changes.py
```

This command will:
- Scan all staged files (`git diff --name-status --cached`)
- Categorize them by type (backend model, frontend component, migration, etc.)
- Suggest appropriate commit type and scope
- Output key=value pairs for programmatic consumption

**Output format** (stdout):
```
type=<commit_type>
scope=<scope>
files_changed=<count>
changed_files=<file1>|<file2>|...
```

**Debug info** (stderr): Category breakdown with file counts

**Exit codes**:
- `0`: Success (commit metadata available)
- `1`: Error (no staged files or git repository issue)

### Step 2: Interpret suggestions

Based on the script output:

- **type**: Conventional Commit type
  - `feat`: New feature (models, endpoints, components)
  - `fix`: Bug fix
  - `docs`: Documentation updates
  - `refactor`: Code restructuring
  - `style`: Formatting/styling
  - `test`: Test additions/updates
  - `chore`: Maintenance, migrations, seeds
  - `perf`: Performance improvements
  - `ci`: CI/CD changes

- **scope**: What part of the system changed
  - `slice`: Complete vertical slice (multiple backend/frontend changes)
  - `db`: Database migration
  - `ui`: UI styling changes
  - `agent`: Agent skills/rules changes
  - `progress`: BUILD-PROGRESS.md updates
  - `misc`: Multiple unrelated areas

### Step 3: Construct the message

Format your commit message using the suggested type and scope:

```
<type>(<scope>): <short description>

<optional body explaining why>

<optional footer with issue references>
```

**Rules**:
- Use imperative mood: "add" not "added"
- Don't capitalize first letter after type/scope
- No period at end of subject line
- Subject line ≤ 50 characters
- Blank line between subject and body

### Step 4: Create the commit

```bash
git commit -m "type(scope): description"
```

For commits with detailed explanations:

```bash
git commit -m "type(scope): description" \
  -m "Explanation of changes and reasoning"
```

## Examples from ESG Project

See `examples/` directory for real commits:
- `example-1-new-vertical-slice.md` - Complete feature slice
- `example-2-database-migration.md` - Schema changes  
- `example-3-other-changes.md` - Other commit types

## Analysis Categories

The script categorizes files into these patterns:

**Backend Structure**:
- `backend_migration`: Database migrations (alembic/versions/)
- `backend_endpoint`: API endpoints (backend/app/api/v1/endpoints/)
- `backend_service`: Business logic (backend/app/services/)
- `backend_model`: ORM models (backend/app/models/)
- `backend_schema`: Request/response schemas
- `backend_core`: Infrastructure (config, security, database)
- `backend_script`: Utility scripts

**Frontend Structure**:
- `frontend_component`: React components
- `frontend_service`: API service layer
- `frontend_type`: TypeScript types/interfaces
- `frontend_page`: Route pages/layouts
- `frontend_style`: Global styles and themes

**Infrastructure**:
- `infra_doc`: Planning and documentation
- `infra_progress`: BUILD-PROGRESS.md tracking
- `agent_config`: Agent skills, rules, workflows
- `test`: Test files

## Constraints and Best Practices

- **Stage first**: Always run `git add` before committing
- **Analyze first**: Run the analysis script to get suggestions
- **No force push**: Never use `git push -f` unless authorized
- **Reference progress**: Include notes about completed work in commit body
- **Vertical slices**: Multi-backend-frontend changes use scope like `feat(slice-5)`
- **Migrations**: Database changes use `chore(db): description` format
- **Complex changes**: Always include detailed body explaining the "why"

## Important Notes

- The analysis script only examines staged files (`git diff --name-status --cached`)
- If no files are staged, the script will exit with code 1
- Category breakdown is written to stderr for debugging
- The script is designed for automation and integrates with shell tooling
- Always verify `git status` before assuming analysis correctness
