# Loaded on demand from ../SKILL.md - Relationship loading strategies and session lifecycle

## Relationship Loading Decision Guide

Choosing the right loading strategy is the single most important performance decision in SQLAlchemy. Wrong choices cause N+1 queries or massive row duplication.

### Loading Strategies Comparison

| Strategy | When to Use | Query Count | Row Duplication | Notes |
|----------|-------------|-------------|-----------------|-------|
| `lazy="select"` (default) | Rarely accessed relations | N+1 if iterated | No | **Avoid in production** - causes one extra query per relation per parent |
| `joinedload` | Always need relation, single-level | 1 query | **Yes** - duplicates parent columns for each child row | Use `.unique()` after execute; collections explode row counts |
| `selectinload` | Most collections, multi-level | 2 queries (parent + IN clause) | No | **Default recommendation** - efficient for collections |
| `subqueryload` | Legacy code, many relations | N+1 but batched | No | Deprecated in favor of `selectinload` |
| `raiseload` | Tests/debugging | 0 (raises instead) | No | Bug detector - catches lazy loads in async context |
| `noload` | Optional relations you never need | 0 | No | Explicit "don't load" - use for optional FKs |

### The "Load Only What You Serialize" Rule

Never eager-load relations you won't serialize. Loading full object graphs wastes memory and slows queries.

```python
# Bad: Load entire graph when you only need IDs
stmt = select(User).options(
    joinedload(User.articles).joinedload(Article.comments)
)

# Good: Load only what you return
stmt = select(User.id, User.username)  # No relations at all

# Or: Load specific relation only
stmt = select(User).options(selectinload(User.articles))
# But don't cascade to Article.comments unless you need it
```

### Why `joinedload` on Collections Explodes Row Counts

```python
# Author has 3 articles, each article has 2 tags
# joinedload creates Cartesian product: 1 × 3 × 2 = 6 rows

stmt = select(Author).options(
    joinedload(Author.articles).joinedload(Article.tags)
)
authors = session.execute(stmt).unique().scalars().all()

# Each author row is duplicated 6 times before .unique() collapses it
# Memory usage: O(parents × children × grandchildren)
```

**Fix**: Use `selectinload` for collections:

```python
stmt = select(Author).options(
    selectinload(Author.articles).selectinload(Article.tags)
)
# Query 1: SELECT authors WHERE ...
# Query 2: SELECT articles WHERE author_id IN (1, 2, 3)
# Query 3: SELECT tags WHERE article_id IN (1, 2, 3, 4, 5, 6)
```

### Decision Table: Which Strategy to Use?

```
Do you need the relation?
├─ No → noload or don't include
├─ Yes, always and it's a scalar (one-to-one, many-to-one) → joinedload
├─ Yes, always and it's a collection (one-to-many, many-to-many) → selectinload
├─ Sometimes, depends on request → lazy="select" (or explicit load per endpoint)
└─ In tests, want to catch lazy loads → raiseload
```

### raiseload as Bug Detector in Tests

Catch accidental lazy loading in async contexts:

```python
# In test setup
from sqlalchemy.orm import raiseload

# Raise on ANY lazy load - catches bugs early
stmt = select(User).options(raiseload("*"))
# Or for specific relation
stmt = select(User).options(raiseload(User.articles))

# Test will fail if code tries to access user.articles
# without explicit eager loading
```

### noload/lazy="selectin" for Optional Relations

When a foreign key is nullable and you rarely need the relation:

```python
class Order(Base):
    __tablename__ = "orders"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    
    # Rarely needed, most orders don't have extended details
    shipping_address: Mapped[Optional["ShippingAddress"]] = relationship(
        lazy="selectin",  # Load only when explicitly accessed
    )

# Usage - only loads when you actually need it
order = session.get(Order, 1)
if order.shipping_address_id:  # Check FK first
    # Now load the relation
    session.refresh(order, attribute_names=["shipping_address"])
```

### Before/After: Query Count Difference

**Before (N+1 problem):**

```python
# List all authors with their article counts
authors = session.execute(select(Author)).scalars().all()
for author in authors:  # 100 authors
    print(author.name, len(author.articles))  # 100 more queries!
# Total: 101 queries
```

**After (single query with selectinload):**

```python
from sqlalchemy.orm import selectinload

stmt = select(Author).options(selectinload(Author.articles))
authors = session.execute(stmt).scalars().all()
for author in authors:
    print(author.name, len(author.articles))  # Already loaded
# Total: 2 queries (authors + articles WHERE author_id IN (...))
```

## Session Lifecycle

### One Session Per Request/Task

Sessions are **not thread-safe** and should never be shared across concurrent operations.

```python
# ❌ BAD: Module-level shared session
db = SessionLocal()  # Shared across all requests - RACE CONDITIONS

# ❌ BAD: Session shared across async tasks
async def process_user(user_id):
    async with shared_session() as session:  # Don't do this!
        ...

# ✅ GOOD: One session per request
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ✅ GOOD: One AsyncSession per concurrent task
async def process_user(user_id: int):
    async with AsyncSessionLocal() as session:  # Fresh session per task
        result = await session.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()
```

### Session.begin() vs Implicit Transaction

```python
# Implicit transaction (default)
with SessionLocal() as session:
    session.add(user)
    session.commit()  # Auto-begins transaction if none exists

# Explicit transaction (recommended for clarity)
with SessionLocal() as session:
    with session.begin():  # Explicit begin/commit/rollback
        session.add(user)
    # Auto-commits on exit, rolls back on exception

# Nested transaction (SAVEPOINT)
with SessionLocal() as session:
    with session.begin():
        session.add(user)
        with session.begin_nested():  # SAVEPOINT
            session.add(related_object)
            # If this fails, rolls back to savepoint, not entire transaction
```

### expire_on_commit=False Trade-off

```python
# Default: expire_on_commit=True
SessionLocal = sessionmaker(engine, expire_on_commit=True)
with SessionLocal() as session:
    user = User(name="test")
    session.add(user)
    session.commit()
    print(user.name)  # Raises DetachedInstanceError - attributes expired

# Common: expire_on_commit=False
SessionLocal = sessionmaker(engine, expire_on_commit=False)
with SessionLocal() as session:
    user = User(name="test")
    session.add(user)
    session.commit()
    print(user.name)  # Works - attributes still populated

# Trade-off:
# ✅ Pros: Can access data after commit (convenient for API responses)
# ❌ Cons: Stale data if DB changed externally (no refresh)
# Recommendation: False for APIs, True for long-running batch jobs
```

### Async Session Rule

```python
# ❌ BAD: Shared async session across awaits
shared_session = AsyncSessionLocal()

async def task1():
    await shared_session.execute(select(User))  # Race condition!

async def task2():
    await shared_session.execute(select(Post))  # Concurrent access!

# ✅ GOOD: One AsyncSession per task
async def task1():
    async with AsyncSessionLocal() as session:
        await session.execute(select(User))

async def task2():
    async with AsyncSessionLocal() as session:
        await session.execute(select(Post))
```

**Key rule**: Never await between session operations on the same session without proper locking. Each `await` yields control and another task could interfere.
