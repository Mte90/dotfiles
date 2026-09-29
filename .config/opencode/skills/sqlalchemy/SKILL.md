---
name: sqlalchemy
description: "Use when working with SQLAlchemy 2.0 in Python - declarative models and relationships, queries and sessions, async engines with FastAPI, Alembic migrations, bulk operations, or PostgreSQL query optimization"
metadata:
  author: mte90
  version: "3.0.0"
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

### Non-Integer Primary Keys

See `references/queries.md` for UUID, string PKs, and composite keys.

```python
import uuid
from sqlalchemy.dialects.postgresql import UUID

# UUID primary key
class Email(Base):
    __tablename__ = "emails"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    subject = Column(String(255))

# String primary key with custom generator
import secrets

def generate_id(prefix: str = "") -> str:
    """Generate a unique string ID."""
    return f"{prefix}{secrets.token_hex(8)}"

class Service(Base):
    __tablename__ = "services"
    id = Column(String(64), primary_key=True, default=lambda: generate_id("svc_"))
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
```

### Transaction Management

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

## Deep Dives

Load these reference files on demand for detailed coverage:

- **`references/queries.md`** - Queries 2.0 style, CTEs, window functions, bulk operations, PostgreSQL optimization
- **`references/async.md`** - Async engines, async sessions, FastAPI integration
- **`references/migrations.md`** - Alembic setup, migration creation, testing strategies
- **`references/debugging.md`** - DetachedInstanceError, lazy loading issues, N+1 queries, session leak detection