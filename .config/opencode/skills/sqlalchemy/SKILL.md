---
name: sqlalchemy
description: "Python SQL toolkit and ORM with expressive query API, relationship mapping, async support, and Alembic migrations"
metadata:
  author: mte90
  version: "1.0.0"
  tags:
    - python
    - orm
    - database
    - sql
    - alembic
    - async
---

# SQLAlchemy

Complete reference for Python SQL toolkit and ORM.

## Overview

SQLAlchemy provides a full suite of well-known enterprise-level persistence patterns, designed for efficient and high-performing database access.

**Key Features:**
- **Core**: SQL expression language for building queries
- **ORM**: Object-relational mapping with declarative models
- **Async**: Full async/await support (SQLAlchemy 2.0+)
- **Migrations**: Alembic integration for schema changes
- **Multiple DBs**: PostgreSQL, MySQL, SQLite, Oracle, SQL Server

### Installation

```bash
pip install sqlalchemy

# With async support
pip install sqlalchemy[asyncio]

# With PostgreSQL async driver
pip install sqlalchemy[asyncio] asyncpg

# With Alembic migrations
pip install alembic

# With specific database drivers
pip install psycopg2-binary  # PostgreSQL
pip install pymysql          # MySQL
pip install aiosqlite        # SQLite async
```

### SQLAlchemy 2.0

This skill covers SQLAlchemy 2.0+ syntax which is the current standard:

```python
# SQLAlchemy 2.0 style (recommended)
from sqlalchemy import select
from sqlalchemy.orm import Session

stmt = select(User).where(User.name == "john")
result = session.execute(stmt)
users = result.scalars().all()
```

## Engine and Connection

### Creating Engine

```python
from sqlalchemy import create_engine

# SQLite
engine = create_engine("sqlite:///database.db")

# PostgreSQL
engine = create_engine("postgresql://user:password@localhost:5432/mydb")

# PostgreSQL with psycopg2
engine = create_engine("postgresql+psycopg2://user:password@localhost/mydb")

# MySQL
engine = create_engine("mysql+pymysql://user:password@localhost:3306/mydb")

# Connection pool settings
engine = create_engine(
    "postgresql://user:password@localhost/mydb",
    pool_size=10,           # Number of connections to keep
    max_overflow=20,        # Additional connections allowed
    pool_timeout=30,        # Seconds to wait for connection
    pool_recycle=3600,      # Recycle connections after 1 hour
    echo=True,              # Log SQL statements
    echo_pool=True,         # Log connection pool events
)
```

### Async Engine

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

# Async engine
async_engine = create_async_engine(
    "postgresql+asyncpg://user:password@localhost/mydb",
    echo=True,
    pool_size=10,
)

# Async session factory
AsyncSessionLocal = sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Usage
async with AsyncSessionLocal() as session:
    result = await session.execute(select(User))
    users = result.scalars().all()
```

### Connection URL Formats

```python
# SQLite
"sqlite:///database.db"              # Relative path
"sqlite:////absolute/path/to/db.db"  # Absolute path
"sqlite:///:memory:"                 # In-memory database

# PostgreSQL
"postgresql://user:password@host:port/database"
"postgresql+asyncpg://user:password@host/database"  # Async

# MySQL
"mysql+pymysql://user:password@host:port/database"
"mysql+aiomysql://user:password@host/database"  # Async

# Oracle
"oracle+cx_oracle://user:password@host:port/?service_name=myservice"

# SQL Server
"mssql+pyodbc://user:password@host/database?driver=ODBC+Driver+17+for+SQL+Server"
```

## Declarative Models

### Basic Model

```python
from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.sql import func
from datetime import datetime

class Base(DeclarativeBase):
    """Base class for all models."""
    pass

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}')>"
```

### Column Types

```python
from sqlalchemy import (
    Column, Integer, BigInteger, SmallInteger,
    String, Text, Unicode, UnicodeText,
    Float, Double, Numeric, Decimal,
    Boolean, Date, Time, DateTime,
    JSON, LargeBinary, Enum,
    ForeignKey, ForeignKeyConstraint,
    Index, UniqueConstraint, CheckConstraint,
)

class Product(Base):
    __tablename__ = "products"
    
    # Integer types
    id = Column(Integer, primary_key=True)
    quantity = Column(Integer, default=0)
    big_id = Column(BigInteger)
    small_int = Column(SmallInteger)
    
    # String types
    name = Column(String(100), nullable=False)
    description = Column(Text)
    code = Column(Unicode(20))  # Unicode support
    
    # Numeric types
    price = Column(Numeric(10, 2))  # Precision, scale
    weight = Column(Float)
    
    # Boolean
    is_available = Column(Boolean, default=True)
    
    # Date/Time
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    published_date = Column(Date)
    open_time = Column(Time)
    
    # JSON
    metadata = Column(JSON)
    tags = Column(JSON)  # PostgreSQL JSONB
    
    # Binary
    image_data = Column(LargeBinary)
    
    # Enum
    status = Column(Enum("draft", "published", "archived", name="product_status"))
```

### Table Arguments

```python
class Article(Base):
    __tablename__ = "articles"
    
    id = Column(Integer, primary_key=True)
    slug = Column(String(100))
    title = Column(String(200))
    author_id = Column(Integer, ForeignKey("users.id"))
    
    # Table-level constraints
    __table_args__ = (
        UniqueConstraint("slug", name="uq_article_slug"),
        Index("ix_article_author", "author_id"),
        CheckConstraint("length(title) > 0", name="ck_article_title"),
        {"schema": "blog"},  # Schema name
    )
```

## Relationships

### One-to-Many

```python
from sqlalchemy.orm import relationship, Mapped, mapped_column
from typing import List, Optional

class Author(Base):
    __tablename__ = "authors"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    
    # One-to-many relationship
    articles: Mapped[List["Article"]] = relationship(
        back_populates="author",
        cascade="all, delete-orphan",
    )

class Article(Base):
    __tablename__ = "articles"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    author_id: Mapped[int] = mapped_column(ForeignKey("authors.id"))
    
    # Relationship to parent
    author: Mapped["Author"] = relationship(back_populates="articles")
```

### Many-to-Many

```python
# Association table
article_tags = Table(
    "article_tags",
    Base.metadata,
    Column("article_id", Integer, ForeignKey("articles.id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", Integer, ForeignKey("tags.id", ondelete="CASCADE"), primary_key=True),
    Column("created_at", DateTime, server_default=func.now()),
)

class Article(Base):
    __tablename__ = "articles"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    
    tags: Mapped[List["Tag"]] = relationship(
        secondary=article_tags,
        back_populates="articles",
    )

class Tag(Base):
    __tablename__ = "tags"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(50), unique=True)
    
    articles: Mapped[List["Article"]] = relationship(
        secondary=article_tags,
        back_populates="tags",
    )
```

### Association Object (Many-to-Many with Extra Fields)

```python
class OrderItem(Base):
    __tablename__ = "order_items"
    
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"), primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), primary_key=True)
    quantity: Mapped[int] = mapped_column(default=1)
    unit_price: Mapped[float] = mapped_column(Numeric(10, 2))
    
    order: Mapped["Order"] = relationship(back_populates="items")
    product: Mapped["Product"] = relationship(back_populates="order_items")

class Order(Base):
    __tablename__ = "orders"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    items: Mapped[List["OrderItem"]] = relationship(back_populates="order", cascade="all, delete-orphan")

class Product(Base):
    __tablename__ = "products"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    order_items: Mapped[List["OrderItem"]] = relationship(back_populates="product")
```

### One-to-One

```python
class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True)
    
    profile: Mapped["UserProfile"] = relationship(
        back_populates="user",
        uselist=False,  # One-to-one
        cascade="all, delete-orphan",
    )

class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True)
    bio: Mapped[Optional[str]] = mapped_column(Text)
    avatar_url: Mapped[Optional[str]] = mapped_column(String(255))
    
    user: Mapped["User"] = relationship(back_populates="profile")
```

### Self-Referential

```python
class Category(Base):
    __tablename__ = "categories"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    parent_id: Mapped[Optional[int]] = mapped_column(ForeignKey("categories.id"))
    
    # Self-referential relationship
    parent: Mapped[Optional["Category"]] = relationship(
        back_populates="children",
        remote_side=[id],
    )
    children: Mapped[List["Category"]] = relationship(
        back_populates="parent",
        cascade="all, delete-orphan",
    )
```

### Relationship Options

```python
class Article(Base):
    # Lazy loading options
    comments: Mapped[List["Comment"]] = relationship(
        lazy="select",      # Default: load on access
        # lazy="joined",    # Eager load with JOIN
        # lazy="subquery",  # Eager load with separate query
        # lazy="dynamic",   # Return query object (for filtering)
        # lazy="noload",    # Don't load
        # lazy="raise",     # Raise error on access
    )
    
    # Cascade options
    items: Mapped[List["Item"]] = relationship(
        cascade="all",              # All operations
        cascade="all, delete-orphan",  # Delete children when parent deleted
        cascade="save-update, merge",  # Only these operations
    )
    
    # Order by
    comments: Mapped[List["Comment"]] = relationship(
        order_by="Comment.created_at.desc()",
    )
```

## Queries (SQLAlchemy 2.0 Style)

### Basic Queries

```python
from sqlalchemy import select
from sqlalchemy.orm import Session

# Select all
stmt = select(User)
users = session.execute(stmt).scalars().all()

# Select with where
stmt = select(User).where(User.is_active == True)
active_users = session.execute(stmt).scalars().all()

# Multiple conditions
stmt = select(User).where(
    User.is_active == True,
    User.created_at > "2024-01-01",
)
users = session.execute(stmt).scalars().all()

# Select specific columns
stmt = select(User.id, User.username, User.email)
result = session.execute(stmt)
for row in result:
    print(f"ID: {row.id}, Username: {row.username}")

# Get by primary key
user = session.get(User, 1)  # Returns None if not found

# Get one
stmt = select(User).where(User.username == "john")
user = session.execute(stmt).scalar_one_or_none()  # None if not found
user = session.execute(stmt).scalar_one()  # Raises if not found
```

### Joins

```python
# Simple join
stmt = select(Article).join(Author)
articles = session.execute(stmt).scalars().all()

# Join with condition
stmt = select(Article).join(Author, Article.author_id == Author.id)

# Multiple joins
stmt = select(Comment).join(Article).join(Author)

# Join with specific columns
stmt = select(Article.title, Author.name).join(Author)
result = session.execute(stmt)
for row in result:
    print(f"{row.title} by {row.name}")

# Left outer join
from sqlalchemy.orm import outerjoin
stmt = select(Author, Article).outerjoin(Article)

# Join to alias (self-join)
from sqlalchemy.orm import aliased
Manager = aliased(Employee)
stmt = select(Employee, Manager).join(
    Manager, Employee.manager_id == Manager.id
)

# Eager loading with joinedload
from sqlalchemy.orm import joinedload
stmt = select(Author).options(joinedload(Author.articles))
authors = session.execute(stmt).unique().scalars().all()

# Selectin load (separate query)
from sqlalchemy.orm import selectinload
stmt = select(Author).options(selectinload(Author.articles))

# Load only specific relationships
stmt = select(Author).options(
    selectinload(Author.articles).selectinload(Article.tags)
)
```

### Filtering

```python
from sqlalchemy import and_, or_, not_, func, desc, asc

# Comparison operators
stmt = select(User).where(User.age > 18)
stmt = select(User).where(User.age >= 18)
stmt = select(User).where(User.age < 65)
stmt = select(User).where(User.name == "John")
stmt = select(User).where(User.name != "John")

# LIKE
stmt = select(User).where(User.name.like("%john%"))
stmt = select(User).where(User.name.ilike("%JOHN%"))  # Case-insensitive

# IN
stmt = select(User).where(User.id.in_([1, 2, 3]))
stmt = select(User).where(User.status.in_(["active", "pending"]))

# NOT IN
stmt = select(User).where(User.id.not_in([1, 2, 3]))

# BETWEEN
stmt = select(User).where(User.age.between(18, 65))

# IS NULL / IS NOT NULL
stmt = select(User).where(User.deleted_at.is_(None))
stmt = select(User).where(User.deleted_at.is_not(None))

# AND / OR / NOT
stmt = select(User).where(
    and_(User.is_active == True, User.age > 18)
)
stmt = select(User).where(
    or_(User.role == "admin", User.role == "moderator")
)
stmt = select(User).where(
    not_(User.is_banned)
)

# Chained filters
stmt = (
    select(User)
    .where(User.is_active == True)
    .where(User.age >= 18)
    .where(User.country == "US")
)
```

### Ordering and Limiting

```python
# Order by
stmt = select(User).order_by(User.created_at)
stmt = select(User).order_by(desc(User.created_at))
stmt = select(User).order_by(User.last_name, User.first_name)

# Limit and offset
stmt = select(User).limit(10)
stmt = select(User).offset(20).limit(10)  # Pagination

# Pagination helper
def paginate(query, page: int, per_page: int = 20):
    return query.offset((page - 1) * per_page).limit(per_page)

stmt = paginate(select(User), page=2)
```

### Aggregation

```python
from sqlalchemy import func, count, sum, avg, max, min

# Count
stmt = select(count()).select_from(User)
total = session.execute(stmt).scalar()

# Count with filter
stmt = select(count(User.id)).where(User.is_active == True)
active_count = session.execute(stmt).scalar()

# Sum, Avg, Min, Max
stmt = select(sum(Order.total))
stmt = select(avg(Product.price))
stmt = select(max(User.age))
stmt = select(min(Product.price))

# Group by
stmt = (
    select(Author.name, count(Article.id))
    .join(Article)
    .group_by(Author.id)
    .order_by(desc(count(Article.id)))
)

# Having
stmt = (
    select(Author.name, count(Article.id).label("article_count"))
    .join(Article)
    .group_by(Author.id)
    .having(count(Article.id) > 5)
)
```

### Subqueries

```python
# Scalar subquery
subq = (
    select(func.avg(Product.price))
    .where(Product.category_id == Category.id)
    .scalar_subquery()
)
stmt = select(Category.name, subq.label("avg_price"))

# IN subquery
subq = select(Article.author_id).where(Article.views > 1000)
stmt = select(Author).where(Author.id.in_(subq))

# EXISTS
from sqlalchemy import exists
subq = select(Article.id).where(Article.author_id == Author.id)
stmt = select(Author).where(exists(subq))

# CTE (Common Table Expression)
cte = (
    select(Author.name, count(Article.id).label("article_count"))
    .join(Article)
    .group_by(Author.id)
    .cte("author_stats")
)
stmt = select(cte).where(cte.c.article_count > 10)
```

## Sessions

### Session Management

```python
from sqlalchemy.orm import Session, sessionmaker

# Create session factory
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)

# Use session with context manager
with SessionLocal() as session:
    user = session.execute(select(User)).scalar()
    session.commit()

# Manual management
session = SessionLocal()
try:
    user = session.execute(select(User)).scalar()
    session.commit()
finally:
    session.close()

# Dependency injection (FastAPI style)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### Adding and Updating

```python
# Add single object
user = User(username="john", email="john@example.com")
session.add(user)
session.commit()
session.refresh(user)  # Refresh to get server-generated values

# Add multiple objects
users = [
    User(username="user1", email="user1@example.com"),
    User(username="user2", email="user2@example.com"),
]
session.add_all(users)
session.commit()

# Update object
user = session.get(User, 1)
user.email = "newemail@example.com"
session.commit()

# Update with query
from sqlalchemy import update
stmt = (
    update(User)
    .where(User.is_active == True)
    .values(last_login=func.now())
)
session.execute(stmt)
session.commit()

# Update with returning
stmt = (
    update(User)
    .where(User.id == 1)
    .values(email="new@example.com")
    .returning(User)
)
result = session.execute(stmt)
updated_user = result.scalar_one()
session.commit()
```

### Deleting

```python
# Delete object
user = session.get(User, 1)
session.delete(user)
session.commit()

# Delete with query
from sqlalchemy import delete
stmt = delete(User).where(User.is_active == False)
session.execute(stmt)
session.commit()

# Delete with returning
stmt = (
    delete(User)
    .where(User.id == 1)
    .returning(User.id, User.username)
)
result = session.execute(stmt)
deleted = result.fetchone()
session.commit()
```

### Transactions

```python
# Nested transaction (SAVEPOINT)
with session.begin_nested():
    session.add(User(username="test"))
    # Auto-rollback on exception

# Manual transaction control
session.begin()
try:
    session.add(user)
    session.commit()
except:
    session.rollback()
    raise

# Using begin() context manager
with session.begin():
    session.add(user)
    # Auto-commit or rollback
```

### Bulk Operations

```python
# Bulk insert (no events, no relationships)
session.execute(
    insert(User),
    [
        {"username": "user1", "email": "user1@example.com"},
        {"username": "user2", "email": "user2@example.com"},
    ]
)
session.commit()

# Bulk update
session.execute(
    update(User)
    .where(User.is_active == True)
    .values(last_login=func.now())
)

# ORM bulk operations (with events)
session.bulk_insert_mappings(User, [
    {"username": "user1", "email": "user1@example.com"},
    {"username": "user2", "email": "user2@example.com"},
])

session.bulk_update_mappings(User, [
    {"id": 1, "email": "new1@example.com"},
    {"id": 2, "email": "new2@example.com"},
])
```

## Async SQLAlchemy

### Async Models and Session

```python
from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker,
)
from sqlalchemy.orm import Mapped, mapped_column

# Async engine
engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")

# Async session factory
async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Async context manager
async with async_session() as session:
    async with session.begin():
        result = await session.execute(select(User))
        users = result.scalars().all()
```

### Async Queries

```python
from sqlalchemy import select

async def get_user(user_id: int) -> Optional[User]:
    async with async_session() as session:
        result = await session.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

async def get_users_paginated(page: int, per_page: int) -> List[User]:
    async with async_session() as session:
        stmt = (
            select(User)
            .order_by(User.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
        )
        result = await session.execute(stmt)
        return result.scalars().all()

async def create_user(username: str, email: str) -> User:
    async with async_session() as session:
        async with session.begin():
            user = User(username=username, email=email)
            session.add(user)
            await session.flush()
            await session.refresh(user)
            return user
```

### Async with FastAPI

```python
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

app = FastAPI()

async def get_db():
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()

@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.post("/users")
async def create_user(
    username: str,
    email: str,
    db: AsyncSession = Depends(get_db)
):
    user = User(username=username, email=email)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user
```

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

## PostgreSQL Query Optimization

### EXPLAIN ANALYZE with SQLAlchemy

```python
from sqlalchemy import text

def analyze_query(session, query):
    """Run EXPLAIN ANALYZE on a query."""
    compiled = query.statement.compile(session.bind)
    explain_sql = text(f"EXPLAIN ANALYZE {compiled}")
    result = session.execute(explain_sql).fetchall()
    for row in result:
        print(row[0])
```

### Index strategy

When to add indexes:

```python
# Add index for frequently filtered columns
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    email = Column(String, index=True)  # Frequently filtered
    created_at = Column(DateTime, index=True)  # Frequently sorted

# Composite index for multi-column filters
class Event(Base):
    __tablename__ = "events"
    __table_args__ = (
        Index("ix_event_user_date", "user_id", "created_at"),  # Composite
    )
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime)
```

### Read-only transactions for metrics endpoints

```python
from sqlalchemy.orm import Session

def get_metrics(session: Session):
    """Read-only metrics query — no writes, no locks."""
    # Use execution_options for read-only
    result = session.execute(
        text("SELECT status, COUNT(*) FROM services WHERE active = true GROUP BY status"),
        execution_options={"read_only": True}
    )
    return result.fetchall()
```

### Query plan optimization

Detecting and fixing slow queries:

```python
# Check for sequential scans (should use index scan)
def check_query_plan(session, query):
    compiled = query.statement.compile(session.bind)
    plan = session.execute(text(f"EXPLAIN {compiled}")).fetchall()
    plan_text = "\n".join(row[0] for row in plan)
    
    if "Seq Scan" in plan_text:
        logger.warning(f"Sequential scan detected — consider adding index:\n{plan_text}")
    return plan_text
```

### Partitioning large tables

Time-series partitioning pattern:

```python
# PostgreSQL native partitioning via raw SQL in migration
def upgrade():
    op.execute("""
        CREATE TABLE events (
            id SERIAL,
            created_at TIMESTAMP NOT NULL,
            data JSONB
        ) PARTITION BY RANGE (created_at);
    """)
    op.execute("""
        CREATE TABLE events_2026_01 
        PARTITION OF events 
        FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
    """)
```

### Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| Slow /metrics endpoint | Loading all history | Read-only transaction with filtered query |
| Sequential scan on large table | Missing index | Add index on filtered column |
| Lock contention | Read-write transaction for read-only query | Use `read_only` execution option |
| N+1 queries | Lazy loading in loop | Use `joinedload()` or `selectinload()` |

## Non-Integer Primary Keys

### UUID primary keys

```python
import uuid
from sqlalchemy.dialects.postgresql import UUID

class Email(Base):
    __tablename__ = "emails"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    subject = Column(String(255))
```

### String primary keys

Custom ID generation pattern:

```python
import secrets

def generate_id(prefix: str = "") -> str:
    """Generate a unique string ID."""
    return f"{prefix}{secrets.token_hex(8)}"

class Email(Base):
    __tablename__ = "emails"
    id = Column(String(64), primary_key=True, default=lambda: generate_id("email_"))
    subject = Column(String(255))
```

### Auto-generation strategies

```python
# UUID with server_default (PostgreSQL)
class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))

# String ID with Python-side default
class Service(Base):
    __tablename__ = "services"
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
```

### Composite primary keys

```python
# Multi-column primary key
class RolePermission(Base):
    __tablename__ = "role_permissions"
    role_id = Column(Integer, ForeignKey("roles.id"), primary_key=True)
    permission_id = Column(Integer, ForeignKey("permissions.id"), primary_key=True)
    # No separate id column — composite PK
```

### Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| ID collision with string IDs | Weak random generator | Use `secrets` module, not `random` |
| UUID not stored efficiently | Storing as String | Use `UUID(as_uuid=True)` with PostgreSQL |
| Can't auto-increment | Non-integer PK | Set `default=` or `server_default=` |

## Advanced Query Patterns

### CTEs (Common Table Expressions)

```python
from sqlalchemy import CTE

# Recursive CTE: organizational hierarchy
org_cte = select(Employee).where(Employee.manager_id.is_(None)).cte(name="org", recursive=True)
mgr = org_cte.alias("mgr")
stmt = (
    select(mgr)
    .join(org_cte, mgr.c.manager_id == org_cte.c.id)
)
# Non-recursive CTE
active_cte = (
    select(User.id, User.name)
    .where(User.is_active.is_(True))
    .cte("active_users")
)
stmt = select(Order).join(active_cte, Order.user_id == active_cte.c.id)
```

### Window Functions

```python
from sqlalchemy import over

# Row number, rank, dense rank
stmt = (
    select(
        User.name,
        User.salary,
        func.row_number().over(order_by=User.salary.desc()).label("rn"),
        func.rank().over(order_by=User.salary.desc()).label("rank"),
        func.dense_rank().over(order_by=User.salary.desc()).label("drank"),
        func.sum(User.salary).over(partition_by=User.dept).label("dept_total"),
    )
    .order_by(User.salary.desc())
)
for row in session.execute(stmt):
    print(f"{row.name}: ${row.salary} (rank: {row.rank})")
```

## Transaction Management

### Nested Transactions with Savepoints

```python
from sqlalchemy import begin_nested

# Using savepoints for partial rollback
with Session(engine) as session:
    session.begin()
    session.add(User(name="Alice"))

    # Create a savepoint
    nested = session.begin_nested()
    try:
        session.add(Order(user_id=1, amount=100))
        # If this fails, only the nested transaction rolls back
        nested.commit()
    except Exception:
        nested.rollback()
        # Alice is still in the session, only Order was rolled back

    session.commit()
```

### Read-Only Transactions

```python
from sqlalchemy import text

with engine.connect() as conn:
    conn.execute(text("SET TRANSACTION READ ONLY"))
    result = conn.execute(select(User))
    # Any write attempt will raise an error
```

### Session Lifecycle Best Practices

```python
# Pattern 1: Context manager (recommended)
with Session(engine) as session:
    session.add(user)
    session.commit()
# Session automatically closed

# Pattern 2: Async session
from sqlalchemy.ext.asyncio import AsyncSession

async with AsyncSession(async_engine) as session:
    async with session.begin():
        session.add(user)
    # Auto-committed and closed
```

## Bulk Operations

### Bulk Inserts

```python
from sqlalchemy import insert

# Core bulk insert (fastest)
stmt = insert(User).values([
    {"name": "Alice", "email": "alice@example.com"},
    {"name": "Bob", "email": "bob@example.com"},
    {"name": "Charlie", "email": "charlie@example.com"},
])
session.execute(stmt)
session.commit()

# ORM bulk insert (slower, but triggers events)
session.add_all([
    User(name="Alice", email="alice@example.com"),
    User(name="Bob", email="bob@example.com"),
])
session.commit()
```

### Bulk Updates

```python
from sqlalchemy import update

# Core bulk update
stmt = (
    update(User)
    .where(User.is_active.is_(True))
    .values(last_login=func.now())
)
session.execute(stmt)
session.commit()

# Bulk update with binding
stmt = update(User).where(User.name == "old_name").values(name="new_name")
session.execute(stmt)
session.commit()
```

### Bulk Deletes

```python
from sqlalchemy import delete

stmt = delete(User).where(User.last_login < func.now() - text("interval '90 days'"))
result = session.execute(stmt)
session.commit()
print(f"Deleted {result.rowcount} inactive users")
```

### Performance Tips for Large Datasets

```python
# Use yield_per for large result sets
for user in session.scalars(select(User)).yield_per(100):
    process(user)

# Use server-side cursors with stream()
for row in session.stream(select(LargeTable)):
    process(row)

# Batch inserts with executemany
session.execute(insert(User), [
    {"name": f"User {i}", "email": f"user{i}@example.com"}
    for i in range(10000)
], execution_options={"max_rows": 1000})
session.commit()
```

## Best Practices

### 1. Use Mapped Types (SQLAlchemy 2.0)

```python
# Good: Mapped types with type hints
class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50))
    bio: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    articles: Mapped[List["Article"]] = relationship()
```

### 2. Session Scope

```python
# Good: Use context managers
with SessionLocal() as session:
    user = session.execute(select(User)).scalar()
    session.commit()

# Bad: Forget to close
session = SessionLocal()
user = session.execute(select(User)).scalar()
# session.close() missing!
```

### 3. Eager Loading

```python
# Good: Explicit eager loading
stmt = select(Author).options(selectinload(Author.articles))

# Bad: N+1 query problem
authors = session.execute(select(Author)).scalars().all()
for author in authors:
    print(author.articles)  # Triggers query for each author!
```

### 4. Use expire_on_commit=False

```python
# Good: Can access attributes after commit
SessionLocal = sessionmaker(
    bind=engine,
    expire_on_commit=False,  # Access attributes after commit
)

with SessionLocal() as session:
    user = User(username="john")
    session.add(user)
    session.commit()
    print(user.username)  # Works with expire_on_commit=False
```

### 5. Connection Pooling

```python
# Good: Configure pool for production
engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # Check connection health
    pool_recycle=3600,   # Recycle old connections
)
```

## Common Issues & Debugging

### DetachedInstanceError

```python
# Problem: Accessing attributes after session closed
with Session(engine) as session:
    user = session.scalar(select(User).limit(1))
# print(user.name)  # DetachedInstanceError!

# Fix 1: Expire objects on commit = False
session = Session(engine, expire_on_commit=False)

# Fix 2: Access within session context
with Session(engine) as session:
    user = session.scalar(select(User).limit(1))
    name = user.name  # OK, still attached
```

### Lazy Loading Outside Sessions

```python
# Problem: Accessing relationships after session closed
with Session(engine) as session:
    user = session.scalar(select(User).limit(1))
# print(user.posts)  # Error! Relationship not loaded

# Fix: Use eager loading
stmt = select(User).options(selectinload(User.posts))
user = session.scalar(stmt)
print(user.posts)  # OK, already loaded
```

### N+1 Query Problem

```python
# BAD: N+1 queries (1 for users + N for each user's posts)
users = session.scalars(select(User)).all()
for user in users:
    print(len(user.posts))  # Triggers 1 query per user!

# GOOD: Single query with joined eager loading
from sqlalchemy.orm import joinedload
stmt = select(User).options(joinedload(User.posts))
users = session.scalars(stmt).unique().all()

# GOOD: Two queries with selective loading
from sqlalchemy.orm import selectinload
stmt = select(User).options(selectinload(User.posts))
users = session.scalars(stmt).all()
```

### Session Leak Detection

```python
# Enable session tracking for debugging
from sqlalchemy import event

@event.listens_for(Session, "after_commit")
def log_commit(session, context):
    logger.info(f"Session committed: {id(session)}")

@event.listens_for(Session, "after_rollback")
def log_rollback(session, context):
    logger.warning(f"Session rolled back: {id(session)}")

# Use weak_instance_map to track detached instances
# Always use context managers to prevent leaks:
with Session(engine) as session:
    # work...
    session.commit()
# Guaranteed cleanup
```

## References

- **Official Documentation**: https://docs.sqlalchemy.org/
- **SQLAlchemy 2.0 Overview**: https://docs.sqlalchemy.org/en/20/changelog/migration_20.html
- **SQLAlchemy 2.0 Tutorial**: https://docs.sqlalchemy.org/en/20/tutorial/
- **Alembic Documentation**: https://alembic.sqlalchemy.org/
- **Alembic Tutorial**: https://alembic.sqlalchemy.org/en/latest/tutorial.html
- **Async Support**: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
- **ORM Querying Guide**: https://docs.sqlalchemy.org/en/20/orm/queryguide/
- **Core Expression Language**: https://docs.sqlalchemy.org/en/20/core/expression_api.html
