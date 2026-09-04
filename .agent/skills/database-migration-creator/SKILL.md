---
name: database-migration-creator
description: Creates Alembic database migrations interactively with table definitions, constraints, and indexes. Validates migration syntax, provides rollback guidance, and ensures migrations follow ESG database patterns. Use when creating new database tables or modifying database schema.
---

# Database Migration Creator

This skill generates Alembic migrations for database schema changes following sqlalchemy patterns.

## When to use this skill

- New table: "Create migration for new feature"
- Schema change: "Add column to existing table"
- Constraint: "Add unique constraint"
- Index: "Add index for performance"
- Data: "Create data migration"

## How to use this skill

### Step 1: Run migration creator

```bash
python .agent/skills/database-migration-creator/scripts/create_migration.py
```

Options:
- **Create table** - New database table
- **Add column** - Add to existing table
- **Modify column** - Change column definition
- **Add constraint** - Unique, check, FK
- **Add index** - Performance optimization
- **Data migration** - Populate/transform data

### Step 2: Define schema

For new table:
- Table name
- Columns (name, type, constraints)
- Indexes
- Foreign keys

### Step 3: Review migration

Generated file in:
```
backend/alembic/versions/YYYYMMDD_HHMM_<description>.py
```

Review for:
- Correct syntax
- Proper constraints
- Indexes on FKs
- Reversible operations

### Step 4: Test migration

```bash
cd backend
alembic upgrade head
```

Verify table created and works correctly.

## Migration Patterns

### Create Table

```python
"""Create clients table.

Revision ID: abc123def456
Revises: prev_migration_id
Create Date: 2026-02-27T15:30:00
"""

from alembic import op
import sqlalchemy as sa

revision = 'abc123def456'
down_revision = 'xyz789uvw012'
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        'client_company',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('industry', sa.String(length=100), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('created_by', sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['created_by'], ['user.id'], ),
        sa.UniqueConstraint('name'),
    )
    op.create_index('ix_client_company_created_by', 'client_company', ['created_by'])
    op.create_index('ix_client_company_created_at', 'client_company', ['created_at'])

def downgrade() -> None:
    op.drop_index('ix_client_company_created_at', 'client_company')
    op.drop_index('ix_client_company_created_by', 'client_company')
    op.drop_table('client_company')
```

### Add Column

```python
def upgrade() -> None:
    op.add_column(
        'client_company',
        sa.Column('esg_score', sa.Integer(), nullable=True),
    )

def downgrade() -> None:
    op.drop_column('client_company', 'esg_score')
```

### Add Constraint

```python
def upgrade() -> None:
    op.create_unique_constraint(
        'uq_client_company_name',
        'client_company',
        ['name']
    )

def downgrade() -> None:
    op.drop_constraint(
        'uq_client_company_name',
        'client_company',
        type_='unique'
    )
```

## Column Types

Common SQLAlchemy column types:

| Python Type | SQLAlchemy | SQL |
|-------------|-----------|-----|
| `str` | `String` | VARCHAR |
| `int` | `Integer` | INT |
| `float` | `Float` | FLOAT |
| `bool` | `Boolean` | BOOLEAN |
| `datetime` | `DateTime` | TIMESTAMP |
| `text` | `Text` | TEXT |
| `bytes` | `LargeBinary` | BLOB |
| `UUID` | `Uuid` | UUID |
| `JSON` | `JSON` | JSON |

## Constraints

### Nullable

```python
sa.Column('email', sa.String(), nullable=False)  # Required
sa.Column('notes', sa.Text(), nullable=True)     # Optional
```

### Defaults

```python
sa.Column('created_at', sa.DateTime(), default=datetime.utcnow)
sa.Column('is_active', sa.Boolean(), default=True)
sa.Column('status', sa.String(), default='pending')
```

### Primary Key

```python
sa.Column('id', sa.Integer(), primary_key=True)
```

### Foreign Key

```python
sa.Column('created_by', sa.Integer(), sa.ForeignKey('user.id'))
sa.ForeignKeyConstraint(['company_id'], ['client_company.id'])
```

### Unique

```python
sa.Column('email', sa.String(), unique=True)
sa.UniqueConstraint('email', 'company_id')  # Composite unique
```

### Check

```python
sa.CheckConstraint('esg_score >= 0 AND esg_score <= 100')
```

## Indexes

Performance optimization:

```python
# Single column
op.create_index('ix_users_email', 'users', ['email'])

# Composite
op.create_index('ix_contacts_company_name', 'contacts', ['company_id', 'name'])

# Unique index (also constraint)
op.create_index('uq_users_email', 'users', ['email'], unique=True)
```

**Index foreign keys:**

```python
op.create_index('ix_contacts_created_by', 'contacts', ['created_by'])
op.create_index('ix_contacts_company_id', 'contacts', ['company_id'])
```

## Data Migrations

Populate data during migration:

```python
def upgrade() -> None:
    op.add_column('users', sa.Column('role_id', sa.Integer(), nullable=True))
    
    # Populate role_id based on existing data
    connection = op.get_bind()
    connection.execute(
        "UPDATE users SET role_id = 4 WHERE user_type = 'client_user'"
    )
    
    # Make it non-nullable
    op.alter_column('users', 'role_id', nullable=False)

def downgrade() -> None:
    op.drop_column('users', 'role_id')
```

## Running Migrations

### Apply all pending

```bash
cd backend
alembic upgrade head
```

### Apply specific migration

```bash
alembic upgrade abc123def456
```

### Rollback latest

```bash
alembic downgrade -1
```

### Rollback specific

```bash
alembic downgrade xyz789uvw012
```

### View history

```bash
alembic history
```

### Check current revision

```bash
alembic current
```

## Naming Convention

**Alembic revision files:**

```
20260227_1530_abc123def456_create_client_company.py
^date     ^time  ^random_id   ^description
```

**In code:**

```
YYYYMMDD_HHMM_{random_id}_{description}
```

## Tips

✅ **Always reversible** - Downgrade should work  
✅ **Add indexes** - Especially for FK columns  
✅ **Test rollback** - Run downgrade before committing  
✅ **One migration** - One logical change per migration  
✅ **Descriptive names** - "create_client_company" not "update_schema"  

❌ **Don't:**
- Lock in production migrations
- Use raw SQL without good reason
- Skip downgrade function
- Mix schema + data changes
- Modify existing migrations

## Validation

Before committing:

```bash
cd backend

# Apply migration
alembic upgrade head
→ No errors? ✅

# Verify table/columns
psql esg_db -c "\d client_company"
→ Correct structure? ✅

# Test rollback
alembic downgrade -1
→ Succeeded? ✅

# Reapply
alembic upgrade head
→ Worked twice? ✅

# Commit
git add alembic/versions/*.py
git commit -m "chore(db): create client_company table"
```

## See Also

- `vertical-slice-generator` - Generates migrations automatically
- `test-runner` - Test data migrations
- `progress-tracker` - Track migration status
