# Loaded on demand from ../SKILL.md - Queries, optimization, and bulk operations

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
```

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