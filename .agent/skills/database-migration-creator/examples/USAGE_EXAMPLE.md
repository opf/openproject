# Database Migration Creator - Usage Examples

This guide shows how to use the database-migration-creator skill.

## Example 1: Create New Table

```bash
python .agent/skills/database-migration-creator/scripts/create_migration.py
```

**Interactive prompts:**

```
Migration Types:
  1. Create new table
  2. Add column to table
  3. Create index
  4. Exit

Select (1-4): 1

Table name (snake_case): contact
Migration description: Create contact table for CRM
```

**Define columns:**

```
Column 1:
  Column name: id
  Type (String/Integer/DateTime/Boolean/Float/Text/JSON): Integer
  Nullable? (yes/no): no
  Unique? (yes/no): no
  Default value (optional): 
  Foreign key to table (optional): 

Column 2:
  Column name: company_id
  Type: Integer
  Nullable? (yes/no): no
  Unique? (yes/no): no
  Default value (optional): 
  Foreign key to table: client_company

Column 3:
  Column name: name
  Type: String
  Nullable? (yes/no): no
  Unique? (yes/no): no
  Default value (optional): 
  Length (e.g., 255): 255
  Foreign key to table (optional): 

Column 4:
  Column name: (blank to finish)
```

**Generated migration file:**

`backend/alembic/versions/20260228_1430_create_contact.py`

```python
"""Create contact table for CRM.

Revision ID: 20260228_1430_create_contact
Revises: 
Create Date: 2026-02-28T14:30:00
"""

from alembic import op
import sqlalchemy as sa

revision = '20260228_1430_create_contact'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        'contact',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('company_id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('created_by', sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['company_id'], ['client_company.id']),
        sa.ForeignKeyConstraint(['created_by'], ['user.id']),
    )
    
    # Add indexes
    op.create_index('ix_contact_company_id', 'contact', ['company_id'])
    op.create_index('ix_contact_created_by', 'contact', ['created_by'])
    op.create_index('ix_contact_created_at', 'contact', ['created_at'])

def downgrade() -> None:
    op.drop_index('ix_contact_created_at', 'contact')
    op.drop_index('ix_contact_created_by', 'contact')
    op.drop_index('ix_contact_company_id', 'contact')
    op.drop_table('contact')
```

## Next Steps After Generation

```bash
cd backend

# 1. Update down_revision to previous migration ID
# Edit alembic/versions/20260228_1430_create_contact.py
# Change: down_revision = 'previous_migration_id'

# 2. Test upgrade
alembic upgrade head
# Output: INFO [alembic.runtime.migration] Running upgrade ... 

# 3. Verify table created
alembic current
# Output: 20260228_1430_create_contact

# 4. Check table structure
psql esg_db -c "\d contact"
# Output:
#         Table "public.contact"
#   Column   |  Type   | Modifiers
# -----------+---------+----------
#  id        | integer | not null
#  company_id| integer | not null
#  name      | character varying(255) | not null

# 5. Test downgrade
alembic downgrade -1

# 6. Verify table gone
psql esg_db -c "\d contact"
# Output: Did not find any relation named "contact"

# 7. Reapply
alembic upgrade head

# 8. Commit
git add alembic/versions/20260228_*.py
git commit -m "chore(db): create contact table for CRM"
```

## Example 2: Add Column to Table

```bash
python .agent/skills/database-migration-creator/scripts/create_migration.py
```

**Prompts:**

```
Migration Types:
  1. Create new table
  2. Add column to table
  3. Create index
  4. Exit

Select (1-4): 2

Table name: contact
Migration description (if auto-generated): add_email_field

Column details:
  Column name: email
  Type: String
  Nullable? (yes/no): no
  Unique? (yes/no): yes
  Default value (optional): 
  Length: 255
```

**Generated:**

`backend/alembic/versions/20260228_1450_add_email_to_contact.py`

```python
"""Add email to contact.

Revision ID: 20260228_1450_add_email_to_contact
Revises: 20260228_1430_create_contact
Create Date: 2026-02-28T14:50:00
"""

from alembic import op
import sqlalchemy as sa

revision = '20260228_1450_add_email_to_contact'
down_revision = '20260228_1430_create_contact'

def upgrade() -> None:
    op.add_column(
        'contact',
        sa.Column('email', sa.String(length=255), nullable=False),
    )
    op.create_unique_constraint('uq_contact_email', 'contact', ['email'])

def downgrade() -> None:
    op.drop_constraint('uq_contact_email', 'contact', type_='unique')
    op.drop_column('contact', 'email')
```

## Example 3: Create Index

```bash
python .agent/skills/database-migration-creator/scripts/create_migration.py
```

**Prompts:**

```
Migration Types:
  1. Create new table
  2. Add column to table
  3. Create index
  4. Exit

Select (1-4): 3

Table name: contact
Columns (comma-separated): company_id, created_at
Unique index? (yes/no): no
```

**Generated:**

```python
def upgrade() -> None:
    op.create_index(
        'ix_contact_company_id_created_at',
        'contact',
        ['company_id', 'created_at'],
        unique=False,
    )

def downgrade() -> None:
    op.drop_index('ix_contact_company_id_created_at', 'contact')
```

## Common Patterns

### Audit Columns (Added Automatically)

Every table gets:

```python
sa.Column('created_at', sa.DateTime(), nullable=False),
sa.Column('updated_at', sa.DateTime(), nullable=False),
sa.Column('created_by', sa.Integer(), nullable=False),
```

### Foreign Keys

```python
sa.Column('company_id', sa.Integer(), nullable=False),
sa.ForeignKeyConstraint(['company_id'], ['client_company.id']),
op.create_index('ix_contact_company_id', 'contact', ['company_id'])
```

### Unique Constraints

```python
sa.UniqueConstraint('email'),
# or
sa.Column('email', sa.String(), unique=True),
```

## Troubleshooting

### "relation already exists" error

```bash
# Run downgrade to remove partially applied migration
alembic downgrade -1

# Then reapply
alembic upgrade head
```

### "FOREIGN KEY constraint failed"

```bash
# Make sure referenced table exists
# If referencing new table, create it first
# Order migrations by dependency
```

### "Invalid migration syntax"

```bash
# Check generated file has:
# - Correct revision ID
# - Correct down_revision
# - Proper upgrade() function
# - Proper downgrade() function
```

## Migration Workflow

1. **Generate** with this tool
2. **Set down_revision** to previous migration
3. **Test upgrade** locally
4. **Test downgrade** locally
5. **Reapply upgrade** to verify
6. **Commit** to version control
7. **Apply in production** after code review

## Best Practices

✅ **Always include downgrade** - You may need to rollback  
✅ **Test both directions** - upgrade AND downgrade  
✅ **Index foreign keys** - Performance critical  
✅ **One change per migration** - Easier to reason about  
✅ **Descriptive names** - "add_email_to_contact" not "update_schema"  
✅ **Test with real data** - Run on staging before production  

❌ **Don't:**
- Forget down_revision
- Skip testing downgrade
- Mix multiple changes
- Use hardcoded values
- Lock tables in production

## See Also

- `vertical-slice-generator` - Generates migrations automatically
- `test-runner` - Test migrations with data
- `progress-tracker` - Track migration status
