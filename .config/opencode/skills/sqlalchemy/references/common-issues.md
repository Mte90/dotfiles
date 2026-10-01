# Loaded on demand from ../SKILL.md - Common Issues & Detection

## Real Failure Modes and Detection

### N+1 Query Detection

**Symptom**: Slow page loads, excessive database queries on list endpoints.

**Detection via `echo=True`:**

```python
engine = create_engine(DATABASE_URL, echo=True)
# Watch logs - multiple identical queries with different IDs = N+1
```

**Detection via query counting in tests:**

```python
from sqlalchemy import event

def count_queries(session):
    """Count queries executed in a block."""
    queries = []
    @event.listens_for(session, "before_cursor_execute")
    def receive_before_cursor_execute(*args, **kwargs):
        queries.append(args[2])  # SQL statement
    return queries

# In test
queries = count_queries(session)
response = client.get("/api/authors")  # Triggers queries
assert len(queries) < 10, f"N+1 detected: {len(queries)} queries"
```

**Detection via `assert_num_queries`:**

```python
from django.test import override_settings  # Or similar utility

@override_settings(SQLALCHEMY_ECHO=True)
def test_author_list_no_n_plus_1():
    with assert_num_queries(2):  # 1 for authors, 1 for articles
        response = client.get("/api/authors")
        assert response.status_code == 200
```

**Fix:**

```python
from sqlalchemy.orm import selectinload

stmt = select(Author).options(selectinload(Author.articles))
authors = session.execute(stmt).scalars().all()
```

---

### MissingGreenletError (Lazy Load Outside Async Context)

**Symptom**: `sqlalchemy.exc.MissingGreenlet: greenlet_spawn has not been called`

**Cause**: Lazy loading triggered outside async session context.

```python
async def get_user(user_id: int):
    async with AsyncSessionLocal() as session:
        user = await session.get(User, user_id)
    return user.name  # ❌ ERROR! Accessing attribute after session closed
    # OR: return user.posts  # ❌ ERROR! Lazy load outside async context
```

**Fix:**

```python
async def get_user(user_id: int):
    async with AsyncSessionLocal() as session:
        # Load relation explicitly
        user = await session.get(User, user_id)
        await session.refresh(user, attribute_names=["posts"])
        return user.posts  # ✅ OK - already loaded
```

Or use eager loading:

```python
async def get_user(user_id: int):
    async with AsyncSessionLocal() as session:
        stmt = select(User).options(selectinload(User.posts))
        result = await session.execute(stmt.where(User.id == user_id))
        user = result.scalar_one_or_none()
        return user.posts  # ✅ OK - pre-loaded
```

---

### StaleDataError (Lost Updates Under Concurrency)

**Symptom**: `sqlalchemy.exc.StaleDataError: Could not refresh identity map`

**Cause**: Two transactions read same row, both modify, second commit fails.

```python
# Transaction A                    # Transaction B
session.get(Account, 1)            # session.get(Account, 1)
account.balance -= 100             # account.balance += 50
session.commit()                   # session.commit()  # ❌ StaleDataError!
```

**Fix - Optimistic Locking:**

```python
class Account(Base):
    __tablename__ = "accounts"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    balance: Mapped[int] = mapped_column(Integer, default=0)
    version: Mapped[int] = mapped_column(Integer, default=0)  # Version column

# Update with version check
from sqlalchemy import update

stmt = (
    update(Account)
    .where(Account.id == 1, Account.version == current_version)
    .values(balance=balance - 100, version=Account.version + 1)
)
result = session.execute(stmt)
if result.rowcount == 0:
    raise ConcurrentModificationError("Account was modified by another transaction")
```

**Fix - Pessimistic Locking:**

```python
# Lock row for update
account = session.get(Account, 1, with_for_update=True)
account.balance -= 100
session.commit()  # ✅ Safe - row was locked
```

---

### DetachedInstanceError (After Commit/Expire)

**Symptom**: `sqlalchemy.exc.DetachedInstanceError: Parent instance <User> is not bound to a Session`

**Cause**: Accessing object or lazy relationship after session closed/expired.

```python
with SessionLocal() as session:
    user = session.get(User, 1)
# print(user.name)  # ❌ ERROR - session closed, object detached
```

**Fix 1 - Access within session:**

```python
with SessionLocal() as session:
    user = session.get(User, 1)
    name = user.name  # ✅ OK - still in session
# Can use 'name' outside, but not user.name if it triggers lazy load
```

**Fix 2 - Eager load relationships:**

```python
with SessionLocal() as session:
    stmt = select(User).options(selectinload(User.posts))
    user = session.execute(stmt).scalar_one()
# print(user.posts)  # ✅ OK - already loaded
```

**Fix 3 - Set expire_on_commit=False:**

```python
SessionLocal = sessionmaker(engine, expire_on_commit=False)
with SessionLocal() as session:
    user = session.get(User, 1)
    session.commit()
print(user.name)  # ✅ OK - not expired (but may be stale)
```

---

### Pool Exhaustion (QueuePool Full)

**Symptom**: `sqlalchemy.exc.TimeoutError: QueuePool limit of size X overflow Y reached`

**Cause**: Too many concurrent connections, connections not returned to pool.

**Detection:**

```python
# Enable pool logging
engine = create_engine(
    DATABASE_URL,
    echo_pool=True,  # Log pool events
)
# Watch for "Pool check-out attempted" spam followed by timeouts
```

**Fix - Tune pool settings:**

```python
engine = create_engine(
    DATABASE_URL,
    pool_size=10,           # Base connection pool size
    max_overflow=20,        # Max extra connections under load
    pool_timeout=30,        # Seconds to wait for available connection
    pool_pre_ping=True,     # Check connection health before use
    pool_recycle=3600,      # Recycle connections after 1 hour
)
```

**Fix - Ensure sessions are closed:**

```python
# ❌ BAD - session leak
def get_user(user_id):
    session = SessionLocal()
    user = session.get(User, user_id)
    return user  # Session never closed!

# ✅ GOOD - context manager
def get_user(user_id):
    with SessionLocal() as session:
        return session.get(User, user_id)
```

**NullPool for Serverless:**

```python
# Serverless (AWS Lambda, Vercel) - no persistent connections
from sqlalchemy.pool import NullPool

engine = create_engine(
    DATABASE_URL,
    poolclass=NullPool,  # No pooling - each request creates new connection
)
# Why: Serverless functions are short-lived; pooling wastes resources
```

---

### Missing Tables/Columns After Migration

**Symptom**: `sqlalchemy.exc.ProgrammingError: relation "users" does not exist`

**Cause**: Migration not run, or model changed without migration.

**Detection:**

```python
# Check if tables exist
from sqlalchemy import inspect

def check_tables(engine):
    inspector = inspect(engine)
    existing = set(inspector.get_table_names())
    expected = {"users", "posts", "comments"}
    missing = expected - existing
    if missing:
        raise RuntimeError(f"Missing tables: {missing}")
```

**Fix:**

```bash
# Generate and apply migration
alembic revision --autogenerate -m "Add missing tables"
alembic upgrade head
```

---

### Type Coercion Errors (PostgreSQL JSONB)

**Symptom**: `sqlalchemy.exc.StatementError: could not adapt type dict to JSONB`

**Cause**: Passing Python objects to JSON/JSONB columns without proper serialization.

**Fix:**

```python
from sqlalchemy.dialects.postgresql import JSONB

class Document(Base):
    __tablename__ = "documents"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    # PostgreSQL JSONB with type hints
    metadata: Mapped[dict] = mapped_column(JSONB)

# ✅ SQLAlchemy handles serialization automatically
doc = Document(metadata={"key": "value"})
session.add(doc)
session.commit()

# Query JSONB fields
from sqlalchemy import text
stmt = select(Document).where(
    text("metadata->>'key' = :val"),
    {"val": "value"}
)
```

---

### Circular Import in Models

**Symptom**: `ImportError: cannot import name 'X' from 'models'`

**Cause**: Models importing each other at module level.

**Fix - Use string annotations:**

```python
# ❌ BAD - circular import
from models import Article  # Imports before User class defined

class User(Base):
    __tablename__ = "users"
    articles: Mapped[List[Article]] = relationship()

# ✅ GOOD - string annotations
class User(Base):
    __tablename__ = "users"
    articles: Mapped[List["Article"]] = relationship()  # Forward reference
```

---

### Batch Size Issues with Large Result Sets

**Symptom**: OOM errors, slow queries on large tables.

**Fix - Use yield_per:**

```python
# Process 1000 rows at a time
for user in session.scalars(select(User)).yield_per(1000):
    process(user)  # Memory stays bounded
```

**Fix - Server-side cursors:**

```python
# PostgreSQL server-side cursor
for row in session.stream(select(LargeTable)):
    process(row)
```
