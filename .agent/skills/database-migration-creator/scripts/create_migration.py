#!/usr/bin/env python3
"""
Database Migration Creator - Generates Alembic migrations interactively.

This script provides an interactive interface for creating database migrations:
- Create new tables with columns and constraints
- Add columns to existing tables
- Create indexes for performance
- Add constraints (unique, check, foreign key)
- Create data migrations

Usage:
    python create_migration.py

Options:
    1. Create new table
    2. Add column to table
    3. Create index
    4. Add constraint
    5. Data migration

Output:
    - Generated Alembic migration file
    - SQLAlchemy syntax (async-ready)
    - Upgrade/downgrade functions
    - Guidance for testing
"""

import subprocess
import sys
import re
from pathlib import Path
from typing import Optional, List, Dict
from datetime import datetime


def find_backend_path() -> Optional[Path]:
    """Find backend directory."""
    current = Path(__file__)
    while current != current.parent:
        if (current / "backend" / "alembic").exists():
            return current / "backend"
        current = current.parent
    return None


def prompt_field_details() -> Dict:
    """Prompt for field details."""
    field = {
        "name": input("  Column name: ").strip(),
        "type": input("  Type (String/Integer/DateTime/Boolean/Float/Text/JSON): ").strip(),
        "length": None,
        "nullable": input("  Nullable? (yes/no): ").strip().lower() in ("y", "yes"),
        "unique": input("  Unique? (yes/no): ").strip().lower() in ("y", "yes"),
        "default": input("  Default value (optional): ").strip(),
        "fk_table": input("  Foreign key to table (optional): ").strip(),
    }
    
    if field["type"] == "String":
        field["length"] = int(input("  Length (e.g., 255): ").strip() or "255")
    
    return field


def generate_table_creation() -> None:
    """Generate create table migration."""
    backend_path = find_backend_path()
    if not backend_path:
        print("ERROR: Backend path not found")
        return
    
    table_name = input("Table name (snake_case): ").strip()
    description = input("Migration description: ").strip()
    
    print("\nDefine columns (enter blank column name to finish):\n")
    
    columns = []
    while True:
        print(f"Column {len(columns) + 1}:")
        field = prompt_field_details()
        if field["name"]:
            columns.append(field)
        else:
            break
    
    # Generate migration file
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    migration_id = f"{timestamp}_create_{table_name}"
    
    # Generate Python code
    code = f'''"""Create {table_name} table.

Revision ID: {migration_id}
Revises: 
Create Date: {datetime.now().isoformat()}
"""

from alembic import op
import sqlalchemy as sa

revision = '{migration_id}'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        '{table_name}',
'''
    
    # Add columns
    for col in columns:
        type_str = col["type"]
        
        if col["type"] == "String":
            type_str = f"String(length={col['length']})"
        elif col["type"] == "DateTime":
            type_str = "DateTime()"
        
        nullable = f", nullable={str(col['nullable']).lower()}"
        
        code += f"        sa.Column('{col['name']}', sa.{type_str}(){nullable}),\n"
    
    # Add standard audit columns
    code += """        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('created_by', sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    
    # Add indexes
    op.create_index('ix_{}_created_by', '{}', ['created_by'])
    op.create_index('ix_{}_created_at', '{}', ['created_at'])

def downgrade() -> None:
    op.drop_index('ix_{}_created_at', '{}')
    op.drop_index('ix_{}_created_by', '{}')
    op.drop_table('{}')
""".format(table_name, table_name, table_name, table_name, table_name, table_name, table_name, table_name, table_name)
    
    # Write migration file
    versions_dir = backend_path / "alembic" / "versions"
    migration_file = versions_dir / f"{migration_id}_{re.sub(r'\\s+', '_', description.lower())}.py"
    
    migration_file.write_text(code)
    
    print(f"\n✅ Created: {migration_file}")
    print("\nNext steps:")
    print("  1. Review the migration file")
    print("  2. Set down_revision to previous migration ID")
    print("  3. Run: alembic upgrade head")
    print("  4. Verify table created correctly")


def add_column_to_table() -> None:
    """Add column to existing table."""
    backend_path = find_backend_path()
    if not backend_path:
        print("ERROR: Backend path not found")
        return
    
    table_name = input("Table name: ").strip()
    
    print("\nColumn details:")
    field = prompt_field_details()
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    migration_id = f"{timestamp}_add_{field['name']}_to_{table_name}"
    
    code = f'''"""Add {field['name']} to {table_name}.

Revision ID: {migration_id}
Revises: 
Create Date: {datetime.now().isoformat()}
"""

from alembic import op
import sqlalchemy as sa

revision = '{migration_id}'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.add_column(
        '{table_name}',
        sa.Column('{field['name']}', sa.{field['type']}(), nullable={str(field['nullable']).lower()}),
    )

def downgrade() -> None:
    op.drop_column('{table_name}', '{field['name']}')
'''
    
    versions_dir = backend_path / "alembic" / "versions"
    migration_file = versions_dir / f"{migration_id}.py"
    
    migration_file.write_text(code)
    
    print(f"\n✅ Created: {migration_file}")


def create_index() -> None:
    """Create database index."""
    backend_path = find_backend_path()
    if not backend_path:
        print("ERROR: Backend path not found")
        return
    
    table_name = input("Table name: ").strip()
    columns_str = input("Columns (comma-separated): ").strip()
    columns = [c.strip() for c in columns_str.split(",")]
    unique = input("Unique index? (yes/no): ").strip().lower() in ("y", "yes")
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    index_name = f"ix_{'u_' if unique else ''}{table_name}_{'_'.join(columns)}"
    migration_id = f"{timestamp}_create_{index_name}"
    
    col_list = ", ".join(f"'{col}'" for col in columns)
    
    code = f'''"""Create index on {table_name}.

Revision ID: {migration_id}
Revises: 
Create Date: {datetime.now().isoformat()}
"""

from alembic import op

revision = '{migration_id}'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_index(
        '{index_name}',
        '{table_name}',
        [{col_list}],
        unique={str(unique).lower()},
    )

def downgrade() -> None:
    op.drop_index('{index_name}', '{table_name}')
'''
    
    versions_dir = backend_path / "alembic" / "versions"
    migration_file = versions_dir / f"{migration_id}.py"
    
    migration_file.write_text(code)
    
    print(f"\n✅ Created: {migration_file}")


if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════════╗
║    Database Migration Creator - ESG Sustainify Alembic          ║
║                                                                ║
║  Create database migrations with interactive prompts           ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    while True:
        print("\nMigration Types:")
        print("  1. Create new table")
        print("  2. Add column to table")
        print("  3. Create index")
        print("  4. Exit")
        
        choice = input("\nSelect (1-4): ").strip()
        
        if choice == "1":
            generate_table_creation()
        elif choice == "2":
            add_column_to_table()
        elif choice == "3":
            create_index()
        elif choice == "4":
            print("Goodbye!")
            break
        else:
            print("Invalid choice")
