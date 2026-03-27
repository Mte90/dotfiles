---
name: sqlalchemy
description: "Python SQL toolkit and ORM with expressive query API, relationship mapping, async support, and Alembic migrations"
metadata:
  author: "OSS AI Skills"
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
    
    # Create foreign key
    op.create_foreign_key(
        'fk_articles_author',
        'articles',
        'users',
        ['author_id'],
        ['id'],
        ondelete='CASCADE',
    )
    
    # Drop foreign key
    op.drop_constraint('fk_articles_author', 'articles', type_='foreignkey')
    
    # Execute raw SQL
    op.execute("UPDATE users SET is_active = TRUE")
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

## Common Issues

### Issue: Detached Instance

```python
# Problem: Accessing relationship on detached object
with SessionLocal() as session:
    user = session.get(User, 1)
# session closed, user is detached
print(user.articles)  # DetachedInstanceError!

# Solution: Eager load or merge
with SessionLocal() as session:
    user = session.execute(
        select(User).options(selectinload(User.articles)).where(User.id == 1)
    ).scalar_one()
    # Now user.articles is loaded
```

### Issue: Flush vs Commit

```python
# flush() - Send SQL to database, don't commit transaction
session.add(user)
session.flush()  # Get user.id from database
profile = UserProfile(user_id=user.id)
session.add(profile)
session.commit()  # Commit both

# commit() - Flush and commit transaction
session.add(user)
session.commit()  # All changes persisted
```

### Issue: Session Thread Safety

```python
# Problem: Session is not thread-safe
# Each thread needs its own session

# Solution: Use scoped_session
from sqlalchemy.orm import scoped_session

Session = scoped_session(sessionmaker(bind=engine))

# In each thread:
session = Session()
# Use session...
Session.remove()  # Clean up
```

## References

- **Official Documentation**: https://docs.sqlalchemy.org/
- **SQLAlchemy 2.0 Migration**: https://docs.sqlalchemy.org/en/20/changelog/migration_20.html
- **Alembic Documentation**: https://alembic.sqlalchemy.org/
- **Async Support**: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
