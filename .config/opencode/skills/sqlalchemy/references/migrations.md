# Loaded on demand from ../SKILL.md - Alembic migrations and testing

## Alembic Migrations

### Setup

```bash
# Initialize Alembic
alembic init alembic

# Edit alembic.ini
sqlalchemy.url = postgresql://user:password@localhost/mydb

# Or use env.py for dynamic URL
```

```python
# alembic/env.py
from logging.config import fileConfig
from sqlalchemy import engine_from_config
from sqlalchemy import pool
from alembic import context
from myapp.models import Base  # Import your models

config = context.config
fileConfig(config.config_file_name)
target_metadata = Base.metadata

def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )
        with context.begin_transaction():
            context.run_migrations()
```

### Creating Migrations

```bash
# Auto-generate migration from model changes
alembic revision --autogenerate -m "Add user table"

# Create empty migration
alembic revision -m "Add custom index"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# Rollback to specific revision
alembic downgrade abc123

# View history
alembic history

# Current revision
alembic current
```

### Migration File

```python
# alembic/versions/abc123_add_user_table.py
"""Add user table

Revision ID: abc123
Revises: 
Create Date: 2024-01-15 10:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = 'abc123'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('username', sa.String(50), nullable=False),
        sa.Column('email', sa.String(255), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('username'),
        sa.UniqueConstraint('email'),
    )
    op.create_index('ix_users_username', 'users', ['username'])

def downgrade():
    op.drop_index('ix_users_username', table_name='users')
    op.drop_table('users')
```

### Common Migration Operations

```python
def upgrade():
    # Create table
    op.create_table(
        'products',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('name', sa.String(100), nullable=False),
    )
    
    # Add column
    op.add_column('users', sa.Column('phone', sa.String(20)))
    
    # Drop column
    op.drop_column('users', 'phone')
    
    # Alter column
    op.alter_column(
        'users',
        'username',
        existing_type=sa.String(50),
        type_=sa.String(100),
        nullable=True,
    )
    
    # Create index
    op.create_index('ix_users_email', 'users', ['email'], unique=True)
    
    # Drop index
    op.drop_index('ix_users_email', table_name='users')
    
    # Drop foreign key
    op.drop_constraint('fk_articles_author', 'articles', type_='foreignkey')
    
    # Execute raw SQL
    op.execute("UPDATE users SET is_active = TRUE")
```

## Migration Testing

Migrations are production-critical code. Untested migrations cause downtime.

### Why test migrations

- Migrations run on every deployment
- Schema changes are irreversible in production
- Data loss from bad migrations is catastrophic

### Testing upgrade path

```python
# tests/test_migrations/test_001_add_email_column.py
import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text

@pytest.fixture
def alembic_config():
    return Config("alembic.ini")

def test_upgrade_adds_email_column(db_engine, alembic_config):
    """Test that upgrade adds the email column."""
    command.upgrade(alembic_config, "head")
    
    with db_engine.connect() as conn:
        result = conn.execute(text("PRAGMA table_info(users)"))
        columns = [row[1] for row in result]
        assert "email" in columns

def test_downgrade_removes_email_column(db_engine, alembic_config):
    """Test that downgrade removes the email column."""
    command.upgrade(alembic_config, "head")
    command.downgrade(alembic_config, "-1")
    
    with db_engine.connect() as conn:
        result = conn.execute(text("PRAGMA table_info(users)"))
        columns = [row[1] for row in result]
        assert "email" not in columns
```

### Testing both directions

Always test **upgrade AND downgrade** — downgrades are your emergency rollback.

### Migration test fixtures

```python
@pytest.fixture
def db_engine():
    """Fresh SQLite DB for each migration test."""
    engine = create_engine("sqlite:///:memory:")
    yield engine
    engine.dispose()
```

### Migration coverage

Measuring which migration files have tests:

```python
# tests/conftest.py
import os
from pathlib import Path

def test_all_migrations_have_tests():
    """Ensure every migration file has a corresponding test."""
    migration_dir = Path("alembic/versions")
    test_dir = Path("tests/test_migrations")
    
    migrations = list(migration_dir.glob("*.py"))
    for migration in migrations:
        # Check if a test file exists
        migration_id = migration.stem.split("_")[0]
        test_files = list(test_dir.glob(f"*{migration_id}*"))
        assert test_files, f"No test for migration {migration.name}"
```

### Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| Migration tests modify shared DB | No isolation | Use in-memory SQLite per test |
| Downgrade not tested | Only testing upgrade | Always test both directions |
| Tests pass locally, fail in CI | SQLite vs PostgreSQL differences | Test against PostgreSQL in CI |