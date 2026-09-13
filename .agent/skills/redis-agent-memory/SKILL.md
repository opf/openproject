---
name: redis-agent-memory
description: Persist and retrieve agent state across sessions using a local JSON store in the ESG repo backend.
---

# Agent Memory

Provides key-value state persistence for the AI agent across sessions.
Storage backend: `backend/.agent_memory.json` (gitignored, never committed).

All keys are automatically namespaced under the `agent:` prefix — do NOT add it manually.

## Script Location

```
backend/scripts/agent_memory.py
```

Run all commands from the **repo root** (`D:\Xampp\htdocs\esg_repo`) in PowerShell.

---

## Methods

### 1. Set Context / State

```powershell
python backend/scripts/agent_memory.py set active_slice "24"
```

### 2. Retrieve Context

```powershell
python backend/scripts/agent_memory.py get active_slice
```

### 3. List All Memory Keys

```powershell
python backend/scripts/agent_memory.py list
```

### 4. Clear State

```powershell
# Clear a specific key
python backend/scripts/agent_memory.py clear active_slice

# Wipe the entire agent namespace
python backend/scripts/agent_memory.py clear
```

---

## Common Keys

| Key | Example Value | Purpose |
|---|---|---|
| `active_slice` | `"24"` | Current vertical slice being worked on |
| `current_branch` | `"feat/session-24-qa-commit"` | Active git branch |
| `last_migration` | `"0009_add_assessments"` | Last Alembic migration applied |
| `pending_commit` | `"true"` | Whether uncommitted work exists |
| `session_goal` | `"Client Portal backend"` | Human-readable session objective |

---

## Safety Rules

- Do **NOT** manually prefix keys with `agent:` — the script handles namespacing.
- Values must be plain strings (JSON-serializable).
- The memory file (`backend/.agent_memory.json`) is gitignored and never committed.
- Omitting `<key>` from `clear` wipes the **entire** agent namespace — use with caution.
