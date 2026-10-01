---
name: sqlalchemy
description: "Use when working with SQLAlchemy 2.0 in Python - declarative models, queries, sessions, async engines, Alembic migrations, relationship loading strategies, N+1 detection, pool exhaustion, or 2.0 migration"
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

Python SQL toolkit and ORM. See [official docs](https://docs.sqlalchemy.org/en/20/) for full API reference.

## Installation

```bash
pip install sqlalchemy[asyncio] alembic
pip install asyncpg  # PostgreSQL async driver
pip install psycopg2-binary  # PostgreSQL sync driver
```

## Engine and Pool Configuration

```python
from sqlalchemy import create_engine

# Basic engine
engine = create_engine("postgresql://user:pass@localhost/db", echo=True)

# Production pool settings
engine = create_engine(
    "postgresql://user:pass@localhost/db",
    pool_size=10,           # Base connection pool
    max_overflow=20,        # Max extra connections under load
    pool_timeout=30,        # Wait time for connection
    pool_recycle=3600,      # Recycle connections after 1 hour
    pool_pre_ping=True,     # Check connection health (critical for pool exhaustion fix)
    echo_pool=True,         # Log pool events for debugging
)
```

### Async Engine

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

async_engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/db",
    echo=True,
)

AsyncSessionLocal = sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)
```

### Serverless (NullPool)

```python
from sqlalchemy.pool import NullPool

# AWS Lambda, Vercel - no persistent connections
engine = create_engine(DATABASE_URL, poolclass=NullPool)
```

## Declarative Models

```python
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from typing import Optional, List

class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship (see Relationship Loading Guide below)
    articles: Mapped[List["Article"]] = relationship(back_populates="author")
    
    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}')>"

class Article(Base):
    __tablename__ = "articles"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    
    author: Mapped["User"] = relationship(back_populates="articles")
```

### Column Types Reference

```python
from sqlalchemy import BigInteger, Text, Numeric, JSON, Enum, LargeBinary

class Product(Base):
    __tablename__ = "products"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(Text)
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    metadata: Mapped[dict] = mapped_column(JSON)
    status: Mapped[str] = mapped_column(Enum("draft", "published", name="product_status"))
```

## Sessions

### Session Lifecycle (Critical)

**One session per request/task, never shared.** Sessions are not thread-safe.

```python
# ✅ GOOD: One session per request
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ✅ GOOD: One AsyncSession per async task
async def process_user(user_id: int):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

# ❌ BAD: Module-level shared session (race conditions)
db = SessionLocal()  # Never do this!
```

### Transaction Management

```python
# Implicit transaction (default)
with SessionLocal() as session:
    session.add(user)
    session.commit()

# Explicit transaction (recommended)
with SessionLocal() as session:
    with session.begin():  # Auto-commit/rollback
        session.add(user)

# Nested transaction (SAVEPOINT)
with SessionLocal() as session:
    with session.begin():
        session.add(user)
        with session.begin_nested():
            session.add(related_object)
            # Rolls back to savepoint on exception
```

### expire_on_commit=False Trade-off

```python
SessionLocal = sessionmaker(engine, expire_on_commit=False)

# ✅ Can access attributes after commit
with SessionLocal() as session:
    user = User(name="test")
    session.add(user)
    session.commit()
    print(user.name)  # Works

# Trade-off: Convenient but may return stale data if DB changed externally
```

## Queries (2.0 Style)

```python
from sqlalchemy import select, update, delete

# Select all
stmt = select(User)
users = session.execute(stmt).scalars().all()

# Select with filter
stmt = select(User).where(User.is_active == True)
users = session.execute(stmt).scalars().all()

# Get by primary key
user = session.get(User, 1)  # Returns None if not found

# Get one
stmt = select(User).where(User.username == "john")
user = session.execute(stmt).scalar_one_or_none()

# Update
stmt = update(User).where(User.id == 1).values(email="new@example.com")
session.execute(stmt)
session.commit()

# Delete
stmt = delete(User).where(User.is_active == False)
session.execute(stmt)
session.commit()
```

See `references/queries.md` for joins, aggregations, CTEs, window functions, and bulk operations.

## Relationship Loading Decision Guide

**The single most important performance decision.** Wrong choices cause N+1 queries or row explosion.

### Strategy Comparison

| Strategy | Query Count | Row Duplication | When to Use |
|----------|-------------|-----------------|-------------|
| `lazy="select"` (default) | N+1 if iterated | No | **Avoid in production** - one extra query per relation |
| `joinedload` | 1 query | **Yes** - duplicates parent columns | Scalar relations only (one-to-one, many-to-one) |
| `selectinload` | 2-3 queries | No | **Default recommendation** - efficient for collections |
| `raiseload` | Raises error | No | Tests/debugging - catch lazy loads |
| `noload` | 0 queries | No | Optional relations you never need |

### Why `joinedload` on Collections Explodes

```python
# Author has 3 articles, each with 2 tags
# joinedload creates: 1 × 3 × 2 = 6 rows (Cartesian product)

stmt = select(Author).options(
    joinedload(Author.articles).joinedload(Article.tags)
)
authors = session.execute(stmt).unique().scalars().all()
# Memory: O(parents × children × grandchildren) - BAD!
```

**Fix**: Use `selectinload` for collections:

```python
stmt = select(Author).options(
    selectinload(Author.articles).selectinload(Article.tags)
)
# Query 1: SELECT authors
# Query 2: SELECT articles WHERE author_id IN (...)
# Query 3: SELECT tags WHERE article_id IN (...)
```

### Decision Table

```
Do you need the relation?
├─ No → noload or don't include
├─ Yes, always, scalar relation → joinedload
├─ Yes, always, collection → selectinload (default recommendation)
├─ Sometimes → lazy="select" or explicit load per endpoint
└─ In tests → raiseload to catch bugs
```

### The "Load Only What You Serialize" Rule

Never eager-load relations you won't return. Loading full object graphs wastes memory.

```python
# Bad: Load entire graph
stmt = select(User).options(
    joinedload(User.articles).joinedload(Article.comments)
)

# Good: Load only what you return
stmt = select(User.id, User.username)  # No relations

# Or: Load specific relation only
stmt = select(User).options(selectinload(User.articles))
# Don't cascade to Article.comments unless needed
```

### raiseload as Bug Detector

```python
from sqlalchemy.orm import raiseload

# Catch ANY lazy load in tests
stmt = select(User).options(raiseload("*"))
# Test fails if code accesses user.articles without eager loading
```

### noload for Optional Relations

```python
class Order(Base):
    __tablename__ = "orders"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    
    # Rarely needed - most orders don't have extended details
    shipping_address: Mapped[Optional["ShippingAddress"]] = relationship(
        lazy="selectin",  # Load only when explicitly accessed
    )
```

### Before/After: Query Count

**Before (N+1):**

```python
authors = session.execute(select(Author)).scalars().all()
for author in authors:  # 100 authors
    print(len(author.articles))  # 100 more queries!
# Total: 101 queries
```

**After (selectinload):**

```python
stmt = select(Author).options(selectinload(Author.articles))
authors = session.execute(stmt).scalars().all()
for author in authors:
    print(len(author.articles))  # Already loaded
# Total: 2 queries
```

See `references/relationships.md` for full session lifecycle rules and async patterns.

## 2.0 Migration Checklist

| Old (1.x) | New (2.0) |
|-----------|-----------|
| `session.query(User).get(1)` | `session.get(User, 1)` |
| `session.query(User).filter(...)` | `session.execute(select(User).where(...))` |
| `Query` object | `select()` + `session.execute()` |
| Implicit autocommit | Explicit `session.commit()` required |
| `engine.execute("SELECT ...")` | Removed - use `session.execute(text("SELECT ..."))` |
| `text("SELECT ...")` without binds | `text("SELECT ...").bindparams(...)` or `:param` in string |
| `MetaData()` | `MetaData(naming_convention={...})` for constraints |

```python
# Before (1.x)
user = session.query(User).filter(User.id == 1).first()

# After (2.0)
user = session.get(User, 1)
# OR
user = session.execute(select(User).where(User.id == 1)).scalar_one_or_none()
```

## Common Issues

See `references/common-issues.md` for detailed detection and fixes:

| Issue | Symptom | Detection |
|-------|---------|-----------|
| **N+1 queries** | Slow list endpoints | `echo=True` shows repeated queries; `assert_num_queries(2)` in tests |
| **MissingGreenletError** | "greenlet_spawn has not been called" | Lazy load outside async context |
| **StaleDataError** | "Could not refresh identity map" | Lost updates under concurrency |
| **DetachedInstanceError** | "Parent instance is not bound to a Session" | Access after commit/expire |
| **Pool exhaustion** | "QueuePool limit reached" | `echo_pool=True` logs; too many open connections |
| **Missing tables** | "relation does not exist" | Migration not run; check with `inspect(engine).get_table_names()` |

See `references/common-issues.md` for:
- **N+1 detection** via `echo=True`, query counting, `assert_num_queries`
- **MissingGreenletError** - lazy load outside async context fix
- **StaleDataError** - optimistic/pessimistic locking patterns
- **DetachedInstanceError** - access within session, eager load, `expire_on_commit=False`
- **Pool exhaustion** - `pool_size`, `max_overflow`, `pool_pre_ping`, `NullPool` for serverless

## Deep Dives

Load these reference files on demand for detailed coverage:

- **`references/queries.md`** - Joins, aggregations, CTEs, window functions, bulk operations, PostgreSQL optimization
- **`references/relationships.md`** - Full relationship loading decision guide, session lifecycle rules, async patterns
- **`references/common-issues.md`** - Real failure modes with detection and fixes (N+1, MissingGreenlet, StaleDataError, DetachedInstanceError, pool exhaustion)
- **`references/migrations.md`** - Alembic setup, migration creation, testing strategies
